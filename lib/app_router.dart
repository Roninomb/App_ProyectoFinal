// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/preentrenamiento_screen.dart';
import 'screens/entrenamiento_screen.dart';
import 'screens/resultado_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/pretrain',
      name: 'pretrain',
      builder: (context, state) {
        final extras = state.extra as Map<String, String>;
        return PreTrainScreen(
          nombre: extras['nombre'] ?? '',
          email: extras['email'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/entrenamiento',
      name: 'entrenamiento',
      builder: (context, state) {
        final extras = state.extra as Map<String, String>;
        return EntrenamientoScreen(
          nombre: extras['nombre'] ?? '',
          email: extras['email'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/resultado',
      name: 'resultado',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return ResultadoScreen(data: extras);
      },
    ),
  ],
);
