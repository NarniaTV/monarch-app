import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shadow_model.dart';

/// Repository para gerenciar operações de Sombras no Firestore
class ShadowRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referência para a coleção de sombras do usuário
  CollectionReference _shadowsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('shadows');
  }

  /// Cria uma nova sombra
  Future<String> createShadow(ShadowModel shadow) async {
    try {
      final docRef = await _shadowsCollection(shadow.userId).add(shadow.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar sombra: $e');
    }
  }

  /// Busca todas as sombras do usuário
  Future<List<ShadowModel>> getAllShadows(String userId) async {
    try {
      final snapshot = await _shadowsCollection(userId)
          .orderBy('extractedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ShadowModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar sombras: $e');
    }
  }

  /// Stream de todas as sombras do usuário
  Stream<List<ShadowModel>> watchShadows(String userId) {
    return _shadowsCollection(userId)
        .orderBy('extractedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShadowModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Busca apenas sombras equipadas
  Future<List<ShadowModel>> getEquippedShadows(String userId) async {
    try {
      final snapshot = await _shadowsCollection(userId)
          .where('isEquipped', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        return ShadowModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar sombras equipadas: $e');
    }
  }

  /// Stream de sombras equipadas
  Stream<List<ShadowModel>> watchEquippedShadows(String userId) {
    return _shadowsCollection(userId)
        .where('isEquipped', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShadowModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Atualiza uma sombra existente
  Future<void> updateShadow(String userId, ShadowModel shadow) async {
    try {
      await _shadowsCollection(userId).doc(shadow.id).update(shadow.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar sombra: $e');
    }
  }

  /// Equipa uma sombra (marca isEquipped = true)
  Future<void> equipShadow(String userId, String shadowId) async {
    try {
      await _shadowsCollection(userId).doc(shadowId).update({
        'isEquipped': true,
      });
    } catch (e) {
      throw Exception('Erro ao equipar sombra: $e');
    }
  }

  /// Desequipa uma sombra (marca isEquipped = false)
  Future<void> unequipShadow(String userId, String shadowId) async {
    try {
      await _shadowsCollection(userId).doc(shadowId).update({
        'isEquipped': false,
      });
    } catch (e) {
      throw Exception('Erro ao desequipar sombra: $e');
    }
  }

  /// Deleta uma sombra
  Future<void> deleteShadow(String userId, String shadowId) async {
    try {
      await _shadowsCollection(userId).doc(shadowId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar sombra: $e');
    }
  }

  /// Conta quantas sombras estão equipadas
  Future<int> countEquippedShadows(String userId) async {
    try {
      final snapshot = await _shadowsCollection(userId)
          .where('isEquipped', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Erro ao contar sombras equipadas: $e');
    }
  }
}
