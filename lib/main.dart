import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const App());
}

const List<String> urls = [
  "https://fastly.picsum.photos/id/237/200/300.jpg?hmac=TmmQSbShHz9CdQm0NkEjx1Dyh_Y984R9LpNrpvH2D_U",
  "https://fastly.picsum.photos/id/866/200/300.jpg?hmac=rcadCENKh4rD6MAp6V_ma-AyWv641M4iiOpe1RyFHeI",
  "https://fastly.picsum.photos/id/985/200/300.jpg?grayscale&hmac=K-JyWCNWpR2zfJHMElM_aJ9nLiaTvofemK-_8LCyRtw",
  "https://fastly.picsum.photos/id/870/200/300.jpg?blur=2&grayscale&hmac=ujRymp644uYVjdKJM7kyLDSsrqNSMVRPnGU99cKl6Vs"
];

class PhotoState {
  String url;
  bool selected = false;
  bool display = true;
  Set<String> tags = {};

  PhotoState(
      {required this.url,
      this.selected = false,
      this.display = true,
      required this.tags});

  PhotoState.clone(PhotoState source,
      {bool? selected, bool? display, Set<String>? tags})
      : this(
            url: source.url,
            selected: selected ??= source.selected,
            display: display ??= source.display,
            tags: tags ??= source.tags);
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Photo Viewer', home: GalleryPage());
  }
}

final tags = {"all", "nature", "cats"};

class GalleryState {
  GalleryState({required this.isTagging, required this.photoStates});

  var isTagging = false;
  var photoStates = List.of(urls.map((url) => PhotoState(url: url, tags: {})));
}

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit()
      : super(GalleryState(
            isTagging: false,
            photoStates:
                List.of(urls.map((url) => PhotoState(url: url, tags: {})))));

  void toggleTagging(String? url, {GalleryState? intermediateState}) {
    intermediateState ??= state;

    var isTagging = !intermediateState.isTagging;
    var newPhotoStates = <PhotoState>[];

    for (var ps in intermediateState.photoStates) {
      var newState = PhotoState.clone(ps);
      newState.selected = isTagging && newState.url == url;
      newPhotoStates.add(newState);
    }
  }

  void onPhotoSelect(String url, bool selected) {
    var newPhotoStates = <PhotoState>[];

    for (var ps in state.photoStates) {
      var newState = PhotoState.clone(ps);
      if (newState.url == url) newState.selected = true;
      newPhotoStates.add(newState);
    }

    emit(GalleryState(isTagging: state.isTagging, photoStates: newPhotoStates));
  }

  void selectTag(String tag) {
    var newPhotoStates = <PhotoState>[];

    if (state.isTagging) {
      if (tag != "all") {
        for (var ps in state.photoStates) {
          var newState = PhotoState.clone(ps);
          if (newState.selected) newState.tags.add(tag);
          newPhotoStates.add(newState);
        }
      }

      toggleTagging(null,
          intermediateState: GalleryState(
              isTagging: state.isTagging, photoStates: newPhotoStates));
    } else {
      for (var ps in state.photoStates) {
        var newState = PhotoState.clone(ps);
        newState.display = tag == "all" || newState.tags.contains(tag);
        newPhotoStates.add(newState);
      }
    }

    emit(GalleryState(isTagging: state.isTagging, photoStates: newPhotoStates));
  }
}

class GalleryPage extends StatelessWidget {
  final String title = 'Image Gallery';

  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.watch<GalleryCubit>();
    var state = cubit.state;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GridView.count(
          primary: false,
          crossAxisCount: 2,
          children: List.of(
            state.photoStates.where((ps) => ps.display).map((st) => Photo(
                  state: st,
                  selectable: state.isTagging,
                  onLongPress: cubit.toggleTagging,
                  onSelect: cubit.onPhotoSelect,
                )),
          )),
      drawer: Drawer(
        child: ListView(
          children: List.of(tags.map((t) => ListTile(
                title: Text(t),
                onTap: () {
                  cubit.selectTag(t);
                  Navigator.of(context).pop();
                },
              ))),
        ),
      ),
    );
  }
}

class Photo extends StatelessWidget {
  final PhotoState state;
  final bool selectable;

  final Function onLongPress;
  final Function onSelect;

  const Photo(
      {super.key,
      required this.state,
      required this.selectable,
      required this.onLongPress,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      GestureDetector(
        onLongPress: () => onLongPress(state.url),
        child: Image.network(state.url),
      )
    ];

    if (selectable) {
      children.add(Positioned(
          left: 20,
          top: 0,
          child: Theme(
            data: Theme.of(context)
                .copyWith(unselectedWidgetColor: Colors.grey[200]),
            child: Checkbox(
              onChanged: (value) => onSelect(state.url, value),
              value: state.selected,
              activeColor: Colors.white,
              checkColor: Colors.black,
            ),
          )));
    }

    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: Stack(
        alignment: Alignment.center,
        children: children,
      ),
    );
  }
}
