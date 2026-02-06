import 'package:cloud_firestore/cloud_firestore.dart';


class DailyActivity {
  final String id;
  final String userId;
  final String activityType;
  final String activity;
  final DateTime timestamp;
  final String date;
  final DateTime activityDateTime;
  final bool isCompleted;
  

  final String originalInput;
  final String translatedInput;
  final String originalLanguage;
  final String confidence;
  final String completeness;
  final String notes;
  

  final HarvestingData? harvestingData;
  final CropManagementData? cropManagementData;
  final LivestockData? livestockData;
  final EquipmentData? equipmentData;
  final MaintenanceData? maintenanceData;
  final PlanningData? planningData;
  
 
  final String processingMethod;
  final String apiVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  DailyActivity({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.activity,
    required this.timestamp,
    required this.date,
    required this.activityDateTime,
    required this.isCompleted,
    required this.originalInput,
    required this.translatedInput,
    required this.originalLanguage,
    required this.confidence,
    required this.completeness,
    required this.notes,
    this.harvestingData,
    this.cropManagementData,
    this.livestockData,
    this.equipmentData,
    this.maintenanceData,
    this.planningData,
    required this.processingMethod,
    required this.apiVersion,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory DailyActivity.fromMap(Map<String, dynamic> map) {
    return DailyActivity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      activityType: map['activityType'] ?? '',
      activity: map['activity'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: map['date'] ?? '',
      activityDateTime: DateTime.parse(map['activityDateTime'] ?? DateTime.now().toIso8601String()),
      isCompleted: map['isCompleted'] ?? false,
      originalInput: map['originalInput'] ?? '',
      translatedInput: map['translatedInput'] ?? '',
      originalLanguage: map['originalLanguage'] ?? 'en',
      confidence: map['confidence'] ?? 'medium',
      completeness: map['completeness'] ?? 'partial',
      notes: map['notes'] ?? '',
      harvestingData: map['harvestingData'] != null ? HarvestingData.fromMap(map['harvestingData']) : null,
      cropManagementData: map['cropManagementData'] != null ? CropManagementData.fromMap(map['cropManagementData']) : null,
      livestockData: map['livestockData'] != null ? LivestockData.fromMap(map['livestockData']) : null,
      equipmentData: map['equipmentData'] != null ? EquipmentData.fromMap(map['equipmentData']) : null,
      maintenanceData: map['maintenanceData'] != null ? MaintenanceData.fromMap(map['maintenanceData']) : null,
      planningData: map['planningData'] != null ? PlanningData.fromMap(map['planningData']) : null,
      processingMethod: map['processingMethod'] ?? 'manual',
      apiVersion: map['apiVersion'] ?? 'v1.0',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'activityType': activityType,
      'activity': activity,
      'timestamp': Timestamp.fromDate(timestamp),
      'date': date,
      'activityDateTime': activityDateTime.toIso8601String(),
      'isCompleted': isCompleted,
      'originalInput': originalInput,
      'translatedInput': translatedInput,
      'originalLanguage': originalLanguage,
      'confidence': confidence,
      'completeness': completeness,
      'notes': notes,
      'harvestingData': harvestingData?.toMap(),
      'cropManagementData': cropManagementData?.toMap(),
      'livestockData': livestockData?.toMap(),
      'equipmentData': equipmentData?.toMap(),
      'maintenanceData': maintenanceData?.toMap(),
      'planningData': planningData?.toMap(),
      'processingMethod': processingMethod,
      'apiVersion': apiVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// Activity-specific data models
class HarvestingData {
  final String? cropHarvested;
  final String? quantity;
  final String? location;
  final String? quality;
  final String? duration;
  final String? marketPrice;
  final String? storageLocation;
  final String? harvestMethod;
  final String? profit;
  final String? usage;
  
  HarvestingData({
    this.cropHarvested,
    this.quantity,
    this.location,
    this.quality,
    this.duration,
    this.marketPrice,
    this.storageLocation,
    this.harvestMethod,
    this.profit,
    this.usage,
  });
  
  factory HarvestingData.fromMap(Map<String, dynamic> map) {
    return HarvestingData(
      cropHarvested: map['cropHarvested'],
      quantity: map['quantity'],
      location: map['location'],
      quality: map['quality'],
      duration: map['duration'],
      marketPrice: map['marketPrice'],
      storageLocation: map['storageLocation'],
      harvestMethod: map['harvestMethod'],
      profit: map['profit'],
      usage: map['usage'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'cropHarvested': cropHarvested,
      'quantity': quantity,
      'location': location,
      'quality': quality,
      'duration': duration,
      'marketPrice': marketPrice,
      'storageLocation': storageLocation,
      'harvestMethod': harvestMethod,
      'profit': profit,
      'usage': usage,
    };
  }
}

class CropManagementData {
  final String? cropType;
  final String? areaCovered;
  final String? activityDescription;
  final String? quantity;
  final String? duration;
  final String? weather;
  final String? location;
  final String? fertilizer;
  final String? pesticides;
  final String? tools;
  final String? seedType;
  
  CropManagementData({
    this.cropType,
    this.areaCovered,
    this.activityDescription,
    this.quantity,
    this.duration,
    this.weather,
    this.location,
    this.fertilizer,
    this.pesticides,
    this.tools,
    this.seedType,
  });
  
  factory CropManagementData.fromMap(Map<String, dynamic> map) {
    return CropManagementData(
      cropType: map['cropType'],
      areaCovered: map['areaCovered'],
      activityDescription: map['activityDescription'],
      quantity: map['quantity'],
      duration: map['duration'],
      weather: map['weather'],
      location: map['location'],
      fertilizer: map['fertilizer'],
      pesticides: map['pesticides'],
      tools: map['tools'],
      seedType: map['seedType'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'cropType': cropType,
      'areaCovered': areaCovered,
      'activityDescription': activityDescription,
      'quantity': quantity,
      'duration': duration,
      'weather': weather,
      'location': location,
      'fertilizer': fertilizer,
      'pesticides': pesticides,
      'tools': tools,
      'seedType': seedType,
    };
  }
}

class LivestockData {
  final String? animalType;
  final String? animalCount;
  final String? activityDescription;
  final String? healthStatus;
  final String? duration;
  final String? feedType;
  final String? feedQuantity;
  final String? location;
  final String? observations;
  
  LivestockData({
    this.animalType,
    this.animalCount,
    this.activityDescription,
    this.healthStatus,
    this.duration,
    this.feedType,
    this.feedQuantity,
    this.location,
    this.observations,
  });
  
  factory LivestockData.fromMap(Map<String, dynamic> map) {
    return LivestockData(
      animalType: map['animalType'],
      animalCount: map['animalCount'],
      activityDescription: map['activityDescription'],
      healthStatus: map['healthStatus'],
      duration: map['duration'],
      feedType: map['feedType'],
      feedQuantity: map['feedQuantity'],
      location: map['location'],
      observations: map['observations'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'animalType': animalType,
      'animalCount': animalCount,
      'activityDescription': activityDescription,
      'healthStatus': healthStatus,
      'duration': duration,
      'feedType': feedType,
      'feedQuantity': feedQuantity,
      'location': location,
      'observations': observations,
    };
  }
}

class EquipmentData {
  final String? equipmentName;
  final String? workType;
  final String? duration;
  final String? condition;
  final String? partsReplaced;
  final String? cost;
  final String? location;
  final String? maintenanceNotes;
  
  EquipmentData({
    this.equipmentName,
    this.workType,
    this.duration,
    this.condition,
    this.partsReplaced,
    this.cost,
    this.location,
    this.maintenanceNotes,
  });
  
  factory EquipmentData.fromMap(Map<String, dynamic> map) {
    return EquipmentData(
      equipmentName: map['equipmentName'],
      workType: map['workType'],
      duration: map['duration'],
      condition: map['condition'],
      partsReplaced: map['partsReplaced'],
      cost: map['cost'],
      location: map['location'],
      maintenanceNotes: map['maintenanceNotes'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'equipmentName': equipmentName,
      'workType': workType,
      'duration': duration,
      'condition': condition,
      'partsReplaced': partsReplaced,
      'cost': cost,
      'location': location,
      'maintenanceNotes': maintenanceNotes,
    };
  }
}

class MaintenanceData {
  final String? maintenanceArea;
  final String? workDone;
  final String? duration;
  final String? materials;
  final String? cost;
  final String? completion;
  final String? tools;
  final String? weather;
  
  MaintenanceData({
    this.maintenanceArea,
    this.workDone,
    this.duration,
    this.materials,
    this.cost,
    this.completion,
    this.tools,
    this.weather,
  });
  
  factory MaintenanceData.fromMap(Map<String, dynamic> map) {
    return MaintenanceData(
      maintenanceArea: map['maintenanceArea'],
      workDone: map['workDone'],
      duration: map['duration'],
      materials: map['materials'],
      cost: map['cost'],
      completion: map['completion'],
      tools: map['tools'],
      weather: map['weather'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'maintenanceArea': maintenanceArea,
      'workDone': workDone,
      'duration': duration,
      'materials': materials,
      'cost': cost,
      'completion': completion,
      'tools': tools,
      'weather': weather,
    };
  }
}

class PlanningData {
  final String? planningType;
  final String? timeframe;
  final String? decisions;
  final String? resources;
  final String? budget;
  final String? nextSteps;
  final String? participants;
  
  PlanningData({
    this.planningType,
    this.timeframe,
    this.decisions,
    this.resources,
    this.budget,
    this.nextSteps,
    this.participants,
  });
  
  factory PlanningData.fromMap(Map<String, dynamic> map) {
    return PlanningData(
      planningType: map['planningType'],
      timeframe: map['timeframe'],
      decisions: map['decisions'],
      resources: map['resources'],
      budget: map['budget'],
      nextSteps: map['nextSteps'],
      participants: map['participants'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'planningType': planningType,
      'timeframe': timeframe,
      'decisions': decisions,
      'resources': resources,
      'budget': budget,
      'nextSteps': nextSteps,
      'participants': participants,
    };
  }
}
