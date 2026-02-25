// lib/screens/statistics_screen.dart
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_cosmo_app/core/di/injection.dart';
import 'package:qr_cosmo_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:qr_cosmo_app/presentation/theme/app_button_styles.dart';
import 'package:qr_cosmo_app/data/models/statistics_model.dart';
import '../widgets/app/app_app_bar.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // Verificar permisos antes de mostrar la pantalla
        final canView = authState is AuthAuthenticated && authState.canViewStatistics;
        if (!canView) {
          return _buildAccessDeniedScreen(context);
        }

        return BlocProvider(
          create: (_) => getIt<StatisticsCubit>()..loadStatistics(),
          child: const _StatisticsView(),
        );
      },
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context) {
    return Scaffold(
      appBar: appAppBar(context: context, title: 'Estadísticas'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.block,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Acceso Denegado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Solo los administradores pueden ver las estadísticas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista interna que escucha el StatisticsCubit
class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appAppBar(
        context: context,
        title: 'Estadísticas',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<StatisticsCubit>().refresh(),
            tooltip: 'Actualizar estadísticas',
          ),
        ],
      ),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          return switch (state) {
            StatisticsInitial() || StatisticsLoading() => _buildLoadingBody(),
            StatisticsError(:final message) => _buildErrorBody(context, message),
            StatisticsLoaded(:final statistics) => _buildSuccessBody(context, statistics),
          };
        },
      ),
    );
  }

  Widget _buildLoadingBody() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBody(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<StatisticsCubit>().refresh(),
              style: AppButtonStyles.primary(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBody(BuildContext context, StatisticsModel statistics) {
    return RefreshIndicator(
      onRefresh: () => context.read<StatisticsCubit>().refresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas específicas para fines de semana
            _buildWeekendStats(statistics),
            const SizedBox(height: 20),

            // Lista de QR no utilizados
            _buildUnusedQrGuests(statistics),
            const SizedBox(height: 20),

            // Invitados frecuentes en fines de semana
            _buildFrequentWeekendGuests(statistics),
          ],
        ),
      ),
    );
  }

  // =============== WEEKEND STATISTICS WIDGETS ===============

  Widget _buildWeekendStats(StatisticsModel statistics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.weekend, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Métricas principales de fin de semana
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _WeekendMetricCard(
                title: 'Total Visitas',
                value: statistics.weekendStats.totalWeekendVisits.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
              _WeekendMetricCard(
                title: 'Viernes',
                value: statistics.weekendStats.fridayVisits.toString(),
                icon: Icons.calendar_today,
                color: Colors.green,
              ),
              _WeekendMetricCard(
                title: 'Sábados',
                value: statistics.weekendStats.saturdayVisits.toString(),
                icon: Icons.calendar_today,
                color: AppColors.primary,
              ),
              _WeekendMetricCard(
                title: 'Invitados Únicos',
                value: statistics.weekendStats.uniqueWeekendGuests.toString(),
                icon: Icons.person,
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Promedio de visitas por fin de semana
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.trending_up, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Promedio fin de semana',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  statistics.weekendStats.averageWeekendVisits.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gráfico de últimos fines de semana
          if (statistics.weekendStats.lastWeekends.isNotEmpty) ...[
            const Text(
              'Últimos Fines de Semana',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: _buildWeekendChart(statistics),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekendChart(StatisticsModel statistics) {
    final maxVisits = statistics.weekendStats.lastWeekends.isEmpty
        ? 1
        : statistics.weekendStats.lastWeekends
            .map((w) => w.visitCount)
            .reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: statistics.weekendStats.lastWeekends.take(6).map((weekend) {
        final height = maxVisits == 0 ? 0.0 : (weekend.visitCount / maxVisits) * 80;
        final dayColor = weekend.dayName == 'Viernes' ? Colors.green : AppColors.primary;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              weekend.visitCount.toString(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: dayColor,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 25,
              height: height < 8 ? 8 : height,
              decoration: BoxDecoration(
                color: dayColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weekend.dayName.substring(0, 3), // Vie, Sáb
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${weekend.date.day}/${weekend.date.month}',
              style: TextStyle(
                fontSize: 7,
                color: Colors.grey[500],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildUnusedQrGuests(StatisticsModel statistics) {
    if (statistics.unusedQrGuests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.qr_code_2,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            Text(
              'Todos los QR han sido utilizados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'QR No Utilizados (${statistics.unusedQrGuests.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(statistics.unusedQrGuests.take(10).map((guest) =>
            _buildUnusedGuestTile(guest)
          )),
          if (statistics.unusedQrGuests.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... y ${statistics.unusedQrGuests.length - 10} más',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnusedGuestTile(GuestFrequency guest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red,
            child: Text(
              guest.name.isNotEmpty ? guest.name[0].toUpperCase() : 'G',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'DNI: ${guest.dni}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Sin usar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentWeekendGuests(StatisticsModel statistics) {
    if (statistics.frequentWeekendGuests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.weekend,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay datos de fines de semana aún',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Invitados Frecuentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(statistics.frequentWeekendGuests.take(5).map((guest) =>
            _buildWeekendGuestTile(guest)
          )),
        ],
      ),
    );
  }

  Widget _buildWeekendGuestTile(GuestFrequency guest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange,
            child: Text(
              guest.name.isNotEmpty ? guest.name[0].toUpperCase() : 'G',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'DNI: ${guest.dni}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${guest.visitCount} visitas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${guest.lastVisit.day}/${guest.lastVisit.month}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _WeekendMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _WeekendMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// Overlay shape para el scanner QR
// TODO: This class is duplicated from lib/screens/scan_qr/widgets/scanner_overlay.dart — may be removable
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    Path getRightTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right - borderRadius, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + borderRadius)
        ..lineTo(rect.right, rect.bottom);
    }

    Path getRightBottomPath(Rect rect) {
      return Path()
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom - borderRadius)
        ..quadraticBezierTo(rect.right, rect.bottom, rect.right - borderRadius, rect.bottom)
        ..lineTo(rect.left, rect.bottom);
    }

    Path getLeftBottomPath(Rect rect) {
      return Path()
        ..moveTo(rect.right, rect.bottom)
        ..lineTo(rect.left + borderRadius, rect.bottom)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - borderRadius)
        ..lineTo(rect.left, rect.top);
    }

    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _cutOutSize = cutOutSize + borderOffset;

    final _rect = Rect.fromLTWH(
      rect.left + borderWidthSize - (_cutOutSize / 2),
      rect.top + (height / 2) - (_cutOutSize / 2),
      _cutOutSize,
      _cutOutSize,
    );

    final _topLeftRect = Rect.fromLTRB(
      _rect.left,
      _rect.top,
      _rect.left + borderLength,
      _rect.top + borderLength,
    );

    final _topRightRect = Rect.fromLTRB(
      _rect.right - borderLength,
      _rect.top,
      _rect.right,
      _rect.top + borderLength,
    );

    final _bottomLeftRect = Rect.fromLTRB(
      _rect.left,
      _rect.bottom - borderLength,
      _rect.left + borderLength,
      _rect.bottom,
    );

    final _bottomRightRect = Rect.fromLTRB(
      _rect.right - borderLength,
      _rect.bottom - borderLength,
      _rect.right,
      _rect.bottom,
    );

    final cutOutRect = Rect.fromLTWH(
      _rect.left + borderOffset,
      _rect.top + borderOffset,
      _rect.width - borderOffset * 2,
      _rect.height - borderOffset * 2,
    );

    return Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()
        ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)))
        ..addPath(getLeftTopPath(_topLeftRect), Offset.zero)
        ..addPath(getRightTopPath(_topRightRect), Offset.zero)
        ..addPath(getRightBottomPath(_bottomRightRect), Offset.zero)
        ..addPath(getLeftBottomPath(_bottomLeftRect), Offset.zero),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _cutOutSize = cutOutSize + borderOffset;

    final _rect = Rect.fromLTWH(
      rect.left + borderWidthSize - (_cutOutSize / 2),
      rect.top + (height / 2) - (_cutOutSize / 2),
      _cutOutSize,
      _cutOutSize,
    );

    final _topLeftRect = Rect.fromLTRB(
      _rect.left,
      _rect.top,
      _rect.left + borderLength,
      _rect.top + borderLength,
    );

    final _topRightRect = Rect.fromLTRB(
      _rect.right - borderLength,
      _rect.top,
      _rect.right,
      _rect.top + borderLength,
    );

    final _bottomLeftRect = Rect.fromLTRB(
      _rect.left,
      _rect.bottom - borderLength,
      _rect.left + borderLength,
      _rect.bottom,
    );

    final _bottomRightRect = Rect.fromLTRB(
      _rect.right - borderLength,
      _rect.bottom - borderLength,
      _rect.right,
      _rect.bottom,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(_topLeftRect, Radius.circular(borderRadius)))
      ..addRRect(RRect.fromRectAndRadius(_topRightRect, Radius.circular(borderRadius)))
      ..addRRect(RRect.fromRectAndRadius(_bottomLeftRect, Radius.circular(borderRadius)))
      ..addRRect(RRect.fromRectAndRadius(_bottomRightRect, Radius.circular(borderRadius)));

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
