import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/activity_record.dart';
import '../../domain/repositories/activity_repository.dart';

abstract class HistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryLoadRequested extends HistoryEvent {}

class HistoryCreateRequested extends HistoryEvent {
  final ActivityRecord record;
  HistoryCreateRequested(this.record);
  @override
  List<Object?> get props => [record];
}

class HistoryUpdateRequested extends HistoryEvent {
  final ActivityRecord record;
  HistoryUpdateRequested(this.record);
  @override
  List<Object?> get props => [record];
}

class HistoryDeleteRequested extends HistoryEvent {
  final int id;
  HistoryDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class HistoryDeleteAllRequested extends HistoryEvent {}

class HistoryStatsRequested extends HistoryEvent {}

abstract class HistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<ActivityRecord> records;
  final Map<String, dynamic>? stats;

  HistoryLoaded({required this.records, this.stats});

  @override
  List<Object?> get props => [records, stats];
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class HistoryOperationSuccess extends HistoryState {
  final String message;
  final List<ActivityRecord> records;

  HistoryOperationSuccess({required this.message, required this.records});

  @override
  List<Object?> get props => [message, records];
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final ActivityRepository _repository;

  HistoryBloc(this._repository) : super(HistoryInitial()) {
    on<HistoryLoadRequested>(_onLoad);
    on<HistoryCreateRequested>(_onCreate);
    on<HistoryUpdateRequested>(_onUpdate);
    on<HistoryDeleteRequested>(_onDelete);
    on<HistoryDeleteAllRequested>(_onDeleteAll);
    on<HistoryStatsRequested>(_onStats);
  }

  Future<void> _onLoad(
      HistoryLoadRequested event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final records = await _repository.getAll();
      final stats = await _repository.getStats();
      emit(HistoryLoaded(records: records, stats: stats));
    } catch (e) {
      emit(HistoryError('Error al cargar el historial: $e'));
    }
  }

  Future<void> _onCreate(
      HistoryCreateRequested event, Emitter<HistoryState> emit) async {
    try {
      await _repository.create(event.record);
      final records = await _repository.getAll();
      emit(HistoryOperationSuccess(
        message: 'Actividad guardada correctamente',
        records: records,
      ));
    } catch (e) {
      emit(HistoryError('Error al guardar la actividad: $e'));
    }
  }

  Future<void> _onUpdate(
      HistoryUpdateRequested event, Emitter<HistoryState> emit) async {
    try {
      await _repository.update(event.record);
      final records = await _repository.getAll();
      emit(HistoryOperationSuccess(
        message: 'Actividad actualizada correctamente',
        records: records,
      ));
    } catch (e) {
      emit(HistoryError('Error al actualizar la actividad: $e'));
    }
  }

  Future<void> _onDelete(
      HistoryDeleteRequested event, Emitter<HistoryState> emit) async {
    try {
      await _repository.delete(event.id);
      final records = await _repository.getAll();
      emit(HistoryOperationSuccess(
        message: 'Actividad eliminada',
        records: records,
      ));
    } catch (e) {
      emit(HistoryError('Error al eliminar la actividad: $e'));
    }
  }

  Future<void> _onDeleteAll(
      HistoryDeleteAllRequested event, Emitter<HistoryState> emit) async {
    try {
      await _repository.deleteAll();
      emit(HistoryOperationSuccess(
        message: 'Historial eliminado completamente',
        records: [],
      ));
    } catch (e) {
      emit(HistoryError('Error al eliminar el historial: $e'));
    }
  }

  Future<void> _onStats(
      HistoryStatsRequested event, Emitter<HistoryState> emit) async {
    try {
      final records = await _repository.getAll();
      final stats = await _repository.getStats();
      emit(HistoryLoaded(records: records, stats: stats));
    } catch (e) {
      emit(HistoryError('Error al cargar estadísticas: $e'));
    }
  }
}
