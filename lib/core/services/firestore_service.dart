
// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import 'package:qr_cosmo_app/data/models/visit_model.dart';
import 'package:qr_cosmo_app/data/models/statistics_model.dart';

@Deprecated(
  'Legacy service — duplicates repository logic. '
  'Use GuestRepository, VisitRepository, or StatisticsRepository instead. '
  'Kept temporarily for migration reference.',
)
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =============== GUESTS ===============

  // Crear nuevo invitado
  Future<String> createGuest(GuestModel guest) async {
    try {
      // Asegurar que siempre tenga ownerId (usar createdBy si no se especifica)
      final guestMap = guest.toMap();
      if (guestMap['ownerId'] == null) {
        guestMap['ownerId'] = guest.createdBy;
      }
      final docRef = await _firestore.collection('guests').add(guestMap);
      return docRef.id;
    } catch (e) {
      throw Exception('Error creando invitado: $e');
    }
  }

  // Obtener invitado por ID
  Future<GuestModel?> getGuestById(String guestId) async {
    try {
      final doc = await _firestore.collection('guests').doc(guestId).get();
      if (doc.exists) {
        return GuestModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo invitado: $e');
    }
  }

  // Buscar invitado por QR code
  Future<GuestModel?> getGuestByQRCode(String qrCode) async {
    try {
      final query = await _firestore
          .collection('guests')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return GuestModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error buscando por QR: $e');
    }
  }

  // Buscar invitado por DNI
  Future<GuestModel?> getGuestByDNI(String dni) async {
    try {
      final query = await _firestore
          .collection('guests')
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return GuestModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error buscando por DNI: $e');
    }
  }

  // Obtener todos los invitados (con paginación)
  Stream<List<GuestModel>> getGuests({int limit = 50}) {
    return _firestore
        .collection('guests')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener todos los invitados (método síncrono para administración)
  Future<List<GuestModel>> getAllGuests() async {
    try {
      final query = await _firestore
          .collection('guests')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo todos los invitados: $e');
    }
  }

  // Actualizar invitado
  Future<void> updateGuest(GuestModel guest) async {
    try {
      await _firestore
          .collection('guests')
          .doc(guest.id)
          .update(guest.toMap());
    } catch (e) {
      throw Exception('Error actualizando invitado: $e');
    }
  }

  // Actualizar estado de invitado (activo/inactivo)
  Future<void> updateGuestStatus(String guestId, bool isActive) async {
    try {
      await _firestore
          .collection('guests')
          .doc(guestId)
          .update({'isActive': isActive});
    } catch (e) {
      throw Exception('Error actualizando estado del invitado: $e');
    }
  }

  // Actualizar nombre y DNI de invitado
  Future<void> updateGuestInfo(String guestId, String name, String dni) async {
    try {
      await _firestore
          .collection('guests')
          .doc(guestId)
          .update({
            'name': name,
            'dni': dni,
          });
    } catch (e) {
      throw Exception('Error actualizando información del invitado: $e');
    }
  }

  // Marcar QR como usado (incrementar visitas y actualizar fecha de uso)
  Future<void> markQRAsUsed(String guestId) async {
    try {
      final guestRef = _firestore.collection('guests').doc(guestId);
      final now = DateTime.now();
      
      await _firestore.runTransaction((transaction) async {
        final guestDoc = await transaction.get(guestRef);
        if (guestDoc.exists) {
          final currentVisits = guestDoc.data()?['totalVisits'] ?? 0;
          transaction.update(guestRef, {
            'totalVisits': currentVisits + 1,
            'lastVisit': Timestamp.fromDate(now),
            'lastUsedDate': Timestamp.fromDate(now), // Actualizar fecha de último uso
            'isActive': true, // QR sigue activo para reutilización
          });
        }
      });
    } catch (e) {
      throw Exception('Error marcando QR como usado: $e');
    }
  }

  // Marcar QR como usado múltiples veces (para invitaciones con varios invitados)
  Future<void> markQRAsUsedMultiple(String guestId, int count) async {
    try {
      final guestRef = _firestore.collection('guests').doc(guestId);
      final now = DateTime.now();
      
      await _firestore.runTransaction((transaction) async {
        final guestDoc = await transaction.get(guestRef);
        if (guestDoc.exists) {
          final currentVisits = guestDoc.data()?['totalVisits'] ?? 0;
          transaction.update(guestRef, {
            'totalVisits': currentVisits + count,
            'lastVisit': Timestamp.fromDate(now),
            'lastUsedDate': Timestamp.fromDate(now), // Actualizar fecha de último uso
            'isActive': true, // QR sigue activo para reutilización
          });
        }
      });
    } catch (e) {
      throw Exception('Error marcando QR como usado múltiples veces: $e');
    }
  }

  // Eliminar invitado (QR) permanentemente
  // Valida que solo el dueño pueda eliminar su QR
  Future<void> deleteGuest(String guestId, String currentUserId) async {
    try {
      // Obtener el invitado para validar ownership
      final guestDoc = await _firestore.collection('guests').doc(guestId).get();
      
      if (!guestDoc.exists) {
        throw Exception('QR no encontrado');
      }
      
      final guestData = guestDoc.data()!;
      final ownerId = guestData['ownerId'] ?? guestData['createdBy'];
      
      // Validar ownership - solo el dueño puede eliminar
      if (ownerId != currentUserId) {
        throw Exception('403: No tienes permiso para eliminar este QR. Solo el dueño puede eliminarlo.');
      }
      
      // Primero eliminar todas las visitas relacionadas
      final visitsQuery = await _firestore
          .collection('visits')
          .where('guestId', isEqualTo: guestId)
          .get();
      
      // Eliminar todas las visitas en batch
      final batch = _firestore.batch();
      for (final visitDoc in visitsQuery.docs) {
        batch.delete(visitDoc.reference);
      }
      
      // Eliminar el invitado
      batch.delete(_firestore.collection('guests').doc(guestId));
      
      await batch.commit();
    } catch (e) {
      // Si el error ya contiene el mensaje 403, re-lanzarlo
      if (e.toString().contains('403')) {
        rethrow;
      }
      throw Exception('Error eliminando invitado: $e');
    }
  }

  // =============== VISITS ===============

  // Registrar nueva visita
  Future<String> createVisit(VisitModel visit) async {
    try {
      final docRef = await _firestore.collection('visits').add(visit.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error registrando visita: $e');
    }
  }

  // Crear múltiples visitas usando batch write (más rápido)
  Future<void> createVisitsBatch(List<VisitModel> visits) async {
    try {
      if (visits.isEmpty) return;
      
      final batch = _firestore.batch();
      for (final visit in visits) {
        final docRef = _firestore.collection('visits').doc();
        batch.set(docRef, visit.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error registrando visitas en batch: $e');
    }
  }

  // Obtener visitas de un invitado
  Stream<List<VisitModel>> getGuestVisits(String guestId) {
    return _firestore
        .collection('visits')
        .where('guestId', isEqualTo: guestId)
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener las últimas visitas de un invitado (método síncrono)
  Future<List<VisitModel>> getLastGuestVisits(String guestId, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('visits')
          .where('guestId', isEqualTo: guestId)
          .orderBy('scannedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo últimas visitas del invitado: $e');
    }
  }

  // Obtener todas las visitas (con paginación)
  Stream<List<VisitModel>> getAllVisits({int limit = 100}) {
    return _firestore
        .collection('visits')
        .orderBy('scannedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener visitas de hoy
  Future<List<VisitModel>> getTodayVisits() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    try {
      final query = await _firestore
          .collection('visits')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scannedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('scannedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo visitas de hoy: $e');
    }
  }

  // =============== STATISTICS ===============

  // Obtener estadísticas generales
  Future<StatisticsModel> getStatistics() async {
    try {
      // Obtener contadores básicos
      final guestsSnapshot = await _firestore.collection('guests').get();
      final visitsSnapshot = await _firestore.collection('visits').get();
      
      final totalGuests = guestsSnapshot.docs.length;
      final totalVisits = visitsSnapshot.docs.length;
      
      // Invitados activos (con totalVisits > 0)
      final activeGuests = guestsSnapshot.docs
          .where((doc) => (doc.data()['totalVisits'] ?? 0) > 0)
          .length;

      // Visitas de hoy
      final todayVisits = await getTodayVisits();

      // Visitas de esta semana
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final thisWeekQuery = await _firestore
          .collection('visits')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      // Visitas de este mes
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      final thisMonthQuery = await _firestore
          .collection('visits')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo))
          .get();

      // Promedio de visitas por invitado
      final averageVisitsPerGuest = totalGuests > 0 ? totalVisits / totalGuests : 0.0;

      // Top invitados frecuentes
      final topFrequentGuests = _getTopFrequentGuests(guestsSnapshot.docs);

      // Visitas diarias de la última semana
      final dailyVisitsLastWeek = await _getDailyVisitsLastWeek();

      // Estadísticas específicas para fines de semana
      final weekendStats = await _getWeekendStats();
      
      // Invitados con QR no utilizado
      final unusedQrGuests = _getUnusedQrGuests(guestsSnapshot.docs);
      
      // Intentos fallidos (simulados por ahora, se puede implementar logging real)
      final failedAttempts = await _getFailedAttempts();
      
      // Invitados frecuentes en fines de semana
      final frequentWeekendGuests = await _getFrequentWeekendGuests();

      return StatisticsModel(
        totalGuests: totalGuests,
        totalVisits: totalVisits,
        activeGuests: activeGuests,
        todayVisits: todayVisits.length,
        thisWeekVisits: thisWeekQuery.docs.length,
        thisMonthVisits: thisMonthQuery.docs.length,
        averageVisitsPerGuest: averageVisitsPerGuest,
        topFrequentGuests: topFrequentGuests,
        dailyVisitsLastWeek: dailyVisitsLastWeek,
        weekendStats: weekendStats,
        unusedQrGuests: unusedQrGuests,
        failedAttempts: failedAttempts,
        frequentWeekendGuests: frequentWeekendGuests,
      );
    } catch (e) {
      throw Exception('Error obteniendo estadísticas: $e');
    }
  }

  List<GuestFrequency> _getTopFrequentGuests(List<QueryDocumentSnapshot> docs) {
    final frequencies = docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final visitCount = data['totalVisits'] ?? 0;
          if (visitCount > 0) {
            return GuestFrequency(
              guestId: doc.id,
              name: data['name'] ?? '',
              dni: data['dni'] ?? '',
              visitCount: visitCount,
              lastVisit: data['lastVisit'] != null 
                  ? (data['lastVisit'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          }
          return null;
        })
        .where((freq) => freq != null)
        .cast<GuestFrequency>()
        .toList();

    frequencies.sort((a, b) => b.visitCount.compareTo(a.visitCount));
    return frequencies.take(10).toList(); // Top 10
  }

  Future<List<DailyVisits>> _getDailyVisitsLastWeek() async {
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));
    
    try {
      final query = await _firestore
          .collection('visits')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      // Agrupar por día
      final Map<String, int> dailyCounts = {};
      
      for (final doc in query.docs) {
        final data = doc.data();
        final timestamp = data['scannedAt'] as Timestamp;
        final date = timestamp.toDate();
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        dailyCounts[dayKey] = (dailyCounts[dayKey] ?? 0) + 1;
      }

      // Crear lista de los últimos 7 días
      final List<DailyVisits> dailyVisits = [];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        dailyVisits.add(DailyVisits(
          date: date,
          visitCount: dailyCounts[dayKey] ?? 0,
        ));
      }

      return dailyVisits;
    } catch (e) {
      throw Exception('Error obteniendo visitas diarias: $e');
    }
  }

  // =============== WEEKEND STATISTICS ===============

  // Obtener estadísticas específicas para fines de semana
  Future<WeekendStats> _getWeekendStats() async {
    try {
      // Obtener visitas de los últimos 30 días para analizar fines de semana
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final query = await _firestore
          .collection('visits')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      int totalWeekendVisits = 0;
      int fridayVisits = 0;
      int saturdayVisits = 0;
      Set<String> uniqueWeekendGuests = {};
      List<WeekendDayStats> lastWeekends = [];

      // Procesar visitas
      for (final doc in query.docs) {
        final data = doc.data();
        final timestamp = data['scannedAt'] as Timestamp;
        final date = timestamp.toDate();
        final weekday = date.weekday;

        // Solo viernes (5) y sábados (6)
        if (weekday == 5 || weekday == 6) {
          totalWeekendVisits++;
          uniqueWeekendGuests.add(data['guestId'] ?? '');
          
          if (weekday == 5) {
            fridayVisits++;
          } else {
            saturdayVisits++;
          }
        }
      }

      // Obtener estadísticas de los últimos fines de semana
      final today = DateTime.now();
      for (int i = 0; i < 8; i++) { // Últimos 8 fines de semana
        final checkDate = today.subtract(Duration(days: i));
        if (checkDate.weekday == 5 || checkDate.weekday == 6) {
          final dayVisits = query.docs.where((doc) {
            final data = doc.data();
            final timestamp = data['scannedAt'] as Timestamp;
            final visitDate = timestamp.toDate();
            return visitDate.year == checkDate.year &&
                   visitDate.month == checkDate.month &&
                   visitDate.day == checkDate.day;
          }).length;

          lastWeekends.add(WeekendDayStats(
            date: checkDate,
            visitCount: dayVisits,
            dayName: checkDate.weekday == 5 ? 'Viernes' : 'Sábado',
          ));
        }
      }

      // Ordenar por fecha (más reciente primero)
      lastWeekends.sort((a, b) => b.date.compareTo(a.date));

      final averageWeekendVisits = lastWeekends.isNotEmpty 
          ? lastWeekends.map((w) => w.visitCount).reduce((a, b) => a + b) / lastWeekends.length
          : 0.0;

      return WeekendStats(
        totalWeekendVisits: totalWeekendVisits,
        fridayVisits: fridayVisits,
        saturdayVisits: saturdayVisits,
        uniqueWeekendGuests: uniqueWeekendGuests.length,
        averageWeekendVisits: averageWeekendVisits,
        lastWeekends: lastWeekends.take(6).toList(), // Últimos 6 fines de semana
      );
    } catch (e) {
      throw Exception('Error obteniendo estadísticas de fin de semana: $e');
    }
  }

  // Obtener invitados con QR no utilizado
  List<GuestFrequency> _getUnusedQrGuests(List<QueryDocumentSnapshot> docs) {
    return docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['totalVisits'] ?? 0) == 0 && (data['isActive'] ?? true);
        })
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return GuestFrequency(
            guestId: doc.id,
            name: data['name'] ?? 'Sin nombre',
            dni: data['dni'] ?? 'Sin DNI',
            visitCount: 0,
            lastVisit: DateTime.now(),
          );
        })
        .toList();
  }

  // Obtener intentos fallidos (simulado por ahora)
  Future<List<FailedAttempt>> _getFailedAttempts() async {
    // Por ahora retornamos una lista vacía
    // En el futuro se puede implementar un logging real de intentos fallidos
    return [];
  }

  // Obtener invitados frecuentes en fines de semana
  Future<List<GuestFrequency>> _getFrequentWeekendGuests() async {
    try {
      // Obtener visitas de los últimos 30 días
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final visitsQuery = await _firestore
          .collection('visits')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      // Filtrar solo visitas de viernes y sábados
      final weekendVisits = visitsQuery.docs.where((doc) {
        final data = doc.data();
        final timestamp = data['scannedAt'] as Timestamp;
        final date = timestamp.toDate();
        return date.weekday == 5 || date.weekday == 6; // Viernes o sábado
      }).toList();

      // Contar visitas por invitado en fines de semana
      Map<String, int> guestWeekendVisits = {};
      Map<String, String> guestNames = {};
      Map<String, String> guestDnis = {};
      Map<String, DateTime> lastWeekendVisits = {};

      for (final visit in weekendVisits) {
        final data = visit.data();
        final guestId = data['guestId'] ?? '';
        final guestName = data['guestName'] ?? '';
        final dni = data['dni'] ?? '';
        final timestamp = data['scannedAt'] as Timestamp;
        final visitDate = timestamp.toDate();

        guestWeekendVisits[guestId] = (guestWeekendVisits[guestId] ?? 0) + 1;
        guestNames[guestId] = guestName;
        guestDnis[guestId] = dni;
        
        if (lastWeekendVisits[guestId] == null || visitDate.isAfter(lastWeekendVisits[guestId]!)) {
          lastWeekendVisits[guestId] = visitDate;
        }
      }

      // Convertir a lista de GuestFrequency
      final frequentWeekendGuests = guestWeekendVisits.entries
          .where((entry) => entry.value > 0)
          .map((entry) => GuestFrequency(
                guestId: entry.key,
                name: guestNames[entry.key] ?? 'Sin nombre',
                dni: guestDnis[entry.key] ?? 'Sin DNI',
                visitCount: entry.value,
                lastVisit: lastWeekendVisits[entry.key] ?? DateTime.now(),
              ))
          .toList();

      // Ordenar por número de visitas (descendente)
      frequentWeekendGuests.sort((a, b) => b.visitCount.compareTo(a.visitCount));

      return frequentWeekendGuests.take(10).toList(); // Top 10
    } catch (e) {
      throw Exception('Error obteniendo invitados frecuentes de fin de semana: $e');
    }
  }
}
