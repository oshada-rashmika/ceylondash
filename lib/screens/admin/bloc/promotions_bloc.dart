import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/database_service.dart';
import '../../../../models/promotion_model.dart';

// --- Events ---
abstract class PromotionsEvent {}
class LoadPromotions extends PromotionsEvent {}
class PromotionsUpdated extends PromotionsEvent {
  final List<PromotionModel> promotions;
  PromotionsUpdated(this.promotions);
}
class AddPromotion extends PromotionsEvent {
  final PromotionModel promotion;
  AddPromotion(this.promotion);
}
class DeletePromotion extends PromotionsEvent {
  final String id;
  DeletePromotion(this.id);
}

class UpdatePromotion extends PromotionsEvent {
  final PromotionModel promotion;
  UpdatePromotion(this.promotion);
}

// --- States ---
abstract class PromotionsState {}
class PromotionsLoading extends PromotionsState {}
class PromotionsLoaded extends PromotionsState {
  final List<PromotionModel> promotions;
  PromotionsLoaded(this.promotions);
}
class PromotionsError extends PromotionsState {
  final String message;
  PromotionsError(this.message);
}

// --- Bloc ---
class PromotionsBloc extends Bloc<PromotionsEvent, PromotionsState> {
  final DatabaseService _db = DatabaseService();
  StreamSubscription? _promotionsSubscription;

  PromotionsBloc() : super(PromotionsLoading()) {
    on<LoadPromotions>(_onLoadPromotions);
    on<PromotionsUpdated>(_onPromotionsUpdated);
    on<AddPromotion>(_onAddPromotion);
    on<DeletePromotion>(_onDeletePromotion);
    on<UpdatePromotion>(_onUpdatePromotion);
  }

  void _onLoadPromotions(LoadPromotions event, Emitter<PromotionsState> emit) {
    emit(PromotionsLoading());
    _promotionsSubscription?.cancel();
    _promotionsSubscription = _db.streamAllPromotions().listen(
      (promos) => add(PromotionsUpdated(promos)),
      onError: (e) => emit(PromotionsError(e.toString())),
    );
  }

  void _onPromotionsUpdated(PromotionsUpdated event, Emitter<PromotionsState> emit) {
    emit(PromotionsLoaded(event.promotions));
  }

  Future<void> _onAddPromotion(AddPromotion event, Emitter<PromotionsState> emit) async {
    try {
      await _db.createPromotion(event.promotion);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onDeletePromotion(DeletePromotion event, Emitter<PromotionsState> emit) async {
    try {
      await _db.deletePromotion(event.id);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onUpdatePromotion(UpdatePromotion event, Emitter<PromotionsState> emit) async {
    try {
      await _db.updatePromotion(event.promotion.id, event.promotion.toMap());
    } catch (e) {
      // Handle error
    }
  }

  @override
  Future<void> close() {
    _promotionsSubscription?.cancel();
    return super.close();
  }
}
