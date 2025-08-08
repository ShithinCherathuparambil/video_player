import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:io';
import '../../domain/entities/video_file.dart';
import '../blocs/favorites_bloc/favorites_bloc.dart';
import '../blocs/favorites_bloc/favorites_event.dart';
import '../blocs/favorites_bloc/favorites_state.dart';
import './video_player_page.dart';
import '../widgets/batch_delete_confirmation_dialog.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../blocs/theme_bloc/theme_bloc.dart';
import '../blocs/theme_bloc/theme_event.dart';
import '../blocs/theme_bloc/theme_state.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: Implement your widget tree here
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
      ),
      body: Center(
        child: Text('Favorites Page Content'),
      ),
    );
  }
}
