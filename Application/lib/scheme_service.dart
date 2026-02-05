import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vfarm/models/govt_scheme_model.dart';

class SchemeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Initialize default schemes
  Future<void> initializeDefaultSchemes() async {
    final schemes = [
      {
        'id': 'pm-kisan',
        'name': 'PM-KISAN',
        'description': 'Pradhan Mantri Kisan Samman Nidhi - Income support of ₹6000 per year to eligible farmer families',
        'imagePath': 'assets/schemes/pm-kisan-scheme.webp',
        'eligibleCropTypes': ['rice', 'wheat', 'cotton', 'sugarcane', 'maize', 'all'],
        'eligibleStates': ['all'],
        'benefits': {
          'amount': 6000,
          'installments': 3,
          'perInstallment': 2000,
          'description': '₹6,000 per year in three equal installments of ₹2,000 each'
        },
        'requiredDocuments': [
          'Aadhaar Card',
          'Bank Account Details',
          'Land Ownership Documents',
          'Passport Size Photo'
        ],
        'eligibilityCriteria': {
          'landHolding': 'All landholding farmer families',
          'farmSize': 'Any size',
          'exclusions': 'Subject to government exclusion criteria'
        },
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'pmfby',
        'name': 'PMFBY',
        'description': 'Pradhan Mantri Fasal Bima Yojana - Crop insurance scheme to protect farmers against crop failure',
        'imagePath': 'assets/schemes/PMFBY.webp',
        'eligibleCropTypes': ['rice', 'wheat', 'cotton', 'sugarcane', 'maize', 'pulses', 'oilseeds'],
        'eligibleStates': ['all'],
        'benefits': {
          'coverage': 'Full crop loss protection',
          'premium': 'Subsidized premium rates',
          'description': 'Financial support in case of crop failure due to natural calamities'
        },
        'requiredDocuments': [
          'Aadhaar Card',
          'Bank Account Details',
          'Land Records',
          'Crop Sowing Certificate',
          'Premium Payment Receipt'
        ],
        'eligibilityCriteria': {
          'cropType': 'Notified crops in notified areas',
          'farmerType': 'Both loanee and non-loanee farmers',
          'includes': 'Sharecroppers and tenant farmers'
        },
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'pmksy',
        'name': 'PMKSY',
        'description': 'Pradhan Mantri Krishi Sinchayee Yojana - Scheme to improve farm water efficiency',
        'imagePath': 'assets/schemes/pmksy.webp',
        'eligibleCropTypes': ['rice', 'wheat', 'cotton', 'sugarcane', 'vegetables', 'fruits'],
        'eligibleStates': ['all'],
        'benefits': {
          'irrigation': 'Improved irrigation facilities',
          'efficiency': 'Enhanced water use efficiency',
          'description': 'Per drop more crop initiative'
        },
        'requiredDocuments': [
          'Aadhaar Card',
          'Land Ownership Documents',
          'Water Source Certificate',
          'Project Proposal',
          'Bank Account Details'
        ],
        'eligibilityCriteria': {
          'priority': 'Small and marginal farmers',
          'area': 'Drought-prone and water-scarce areas',
          'focus': 'Low water use efficiency areas'
        },
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'rkvy',
        'name': 'RKVY',
        'description': 'Rashtriya Krishi Vikas Yojana - Holistic development of agriculture and allied sectors',
        'imagePath': 'assets/schemes/RKVY.png',
        'eligibleCropTypes': ['all'],
        'eligibleStates': ['all'],
        'benefits': {
          'infrastructure': 'Agriculture infrastructure development',
          'technology': 'Modern farming practices support',
          'description': 'Financial assistance for agriculture development'
        },
        'requiredDocuments': [
          'Aadhaar Card',
          'Business Plan',
          'Land Documents',
          'Bank Account Details',
          'Registration Certificate'
        ],
        'eligibilityCriteria': {
          'target': 'All farmers and agri-entrepreneurs',
          'includes': 'Farmer Producer Organizations (FPOs)',
          'focus': 'Rural communities and agriculture development'
        },
        'isActive': true,
        'createdAt': Timestamp.now(),
      }
    ];

    for (var scheme in schemes) {
      await _firestore.collection('govt_schemes').doc(scheme['id'] as String?).set(scheme);
    }
  }

  // Submit application with land proof images (from first document)
  Future<void> submitApplication({
    required String userId,
    required String schemeId,
    required String schemeName,
    required Map<String, dynamic> applicationData,
    required List<File> documents,
    List<File>? landProofImages,
  }) async {
    try {
      // Generate application ID
      final applicationRef = _firestore.collection('applications').doc();
      final applicationId = applicationRef.id;
      
      // Generate tracking number
      final trackingNumber = 'TRK-${DateTime.now().millisecondsSinceEpoch}';

      // Upload documents to Firebase Storage
      final List<String> documentUrls = [];
      for (int i = 0; i < documents.length; i++) {
        final file = documents[i];
        final fileName = '${applicationId}_doc_$i.${file.path.split('.').last}';
        final ref = _storage.ref().child('applications/$applicationId/documents/$fileName');
        
        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        documentUrls.add(downloadUrl);
      }

      // Upload land proof images to Firebase Storage
      final List<String> landProofUrls = [];
      if (landProofImages != null) {
        for (int i = 0; i < landProofImages.length; i++) {
          final file = landProofImages[i];
          final fileName = '${applicationId}_land_proof_$i.${file.path.split('.').last}';
          final ref = _storage.ref().child('applications/$applicationId/land_proof/$fileName');
          
          final uploadTask = await ref.putFile(file);
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          landProofUrls.add(downloadUrl);
        }
      }

      // Create application steps
      final steps = [
        ApplicationStep(
          title: 'Application Submitted',
          description: 'Your application has been submitted successfully',
          isCompleted: true,
          completedAt: DateTime.now(),
          isCurrent: false,
        ),
        ApplicationStep(
          title: 'Document Verification',
          description: 'Documents and land proof are being verified',
          isCompleted: false,
          isCurrent: true,
        ),
        ApplicationStep(
          title: 'Survey Number Validation',
          description: 'Survey number and land details are being validated',
          isCompleted: false,
          isCurrent: false,
        ),
        ApplicationStep(
          title: 'Review Process',
          description: 'Application is under review by officials',
          isCompleted: false,
          isCurrent: false,
        ),
        ApplicationStep(
          title: 'Final Decision',
          description: 'Final decision on your application',
          isCompleted: false,
          isCurrent: false,
        ),
      ];

      // Create application model
      final application = SchemeApplicationModel(
        id: applicationId,
        userId: userId,
        schemeId: schemeId,
        schemeName: schemeName,
        applicationData: {
          ...applicationData,
          'landProofImages': landProofUrls,
        },
        uploadedDocuments: documentUrls,
        status: ApplicationStatus.submitted,
        steps: steps,
        appliedAt: DateTime.now(),
        trackingNumber: trackingNumber,
      );

      // Save to Firestore
      await applicationRef.set(application.toMap());

      // Update user's application history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('applications')
          .doc(applicationId)
          .set({
        'applicationId': applicationId,
        'schemeId': schemeId,
        'schemeName': schemeName,
        'status': ApplicationStatus.submitted.toString(),
        'appliedAt': Timestamp.fromDate(DateTime.now()),
        'trackingNumber': trackingNumber,
      });

    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // Submit application (alternative method from second document)
  Future<String> submitApplicationAlt({
    required String userId,
    required String schemeId,
    required String schemeName,
    required Map<String, dynamic> applicationData,
    required List<File> documents,
  }) async {
    try {
      // Upload documents
      List<String> documentUrls = [];
      for (int i = 0; i < documents.length; i++) {
        final ref = _storage.ref().child(
          'scheme_applications/$userId/$schemeId/${DateTime.now().millisecondsSinceEpoch}_$i.${documents[i].path.split('.').last}'
        );
        await ref.putFile(documents[i]);
        final url = await ref.getDownloadURL();
        documentUrls.add(url);
      }

      // Create application steps
      final steps = [
        ApplicationStep(
          title: 'Application Submitted',
          description: 'Your application has been successfully submitted',
          isCompleted: true,
          completedAt: DateTime.now(),
          isCurrent: false,
        ),
        ApplicationStep(
          title: 'Document Verification',
          description: 'Documents are being verified by the authorities',
          isCompleted: false,
          isCurrent: true,
        ),
        ApplicationStep(
          title: 'Eligibility Check',
          description: 'Checking eligibility criteria',
          isCompleted: false,
          isCurrent: false,
        ),
        ApplicationStep(
          title: 'Final Approval',
          description: 'Final approval and benefit disbursement',
          isCompleted: false,
          isCurrent: false,
        ),
      ];

      // Create application
      final applicationId = _firestore.collection('scheme_applications').doc().id;
      final application = SchemeApplicationModel(
        id: applicationId,
        userId: userId,
        schemeId: schemeId,
        schemeName: schemeName,
        applicationData: applicationData,
        uploadedDocuments: documentUrls,
        status: ApplicationStatus.submitted,
        steps: steps,
        appliedAt: DateTime.now(),
      );

      await _firestore.collection('scheme_applications').doc(applicationId).set(application.toMap());
      
      return applicationId;
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // Get user applications
  Future<List<SchemeApplicationModel>> getUserApplications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SchemeApplicationModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch applications: $e');
    }
  }

  // Get user applications (alternative method from second document)
  Future<List<SchemeApplicationModel>> getUserApplicationsAlt(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('scheme_applications')
          .where('userId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => SchemeApplicationModel.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch applications: $e');
    }
  }

  // Get application by ID
  Future<SchemeApplicationModel?> getApplication(String applicationId) async {
    try {
      final docSnapshot = await _firestore
          .collection('applications')
          .doc(applicationId)
          .get();

      if (docSnapshot.exists) {
        return SchemeApplicationModel.fromSnapshot(docSnapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch application: $e');
    }
  }

  // Get application by ID (alternative method from second document)
  Future<SchemeApplicationModel?> getApplicationById(String applicationId) async {
    try {
      final doc = await _firestore.collection('scheme_applications').doc(applicationId).get();
      if (doc.exists) {
        return SchemeApplicationModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch application: $e');
    }
  }

  // Track application by tracking number
  Future<SchemeApplicationModel?> trackApplication(String trackingNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('applications')
          .where('trackingNumber', isEqualTo: trackingNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SchemeApplicationModel.fromSnapshot(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to track application: $e');
    }
  }

  // Update application status (for admin use)
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? notes,
    double? benefitAmount,
  }) async {
    try {
      final updateData = {
        'status': status.toString(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };

      if (notes != null) {
        updateData['approvalNotes'] = notes;
      }

      if (benefitAmount != null) {
        updateData['benefitAmount'] = benefitAmount;
      }

      await _firestore
          .collection('applications')
          .doc(applicationId)
          .update(updateData);

    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  // Get all schemes
  Future<List<GovtSchemeModel>> getAllSchemes() async {
    try {
      // Try govt_schemes collection first (from second document)
      final govtSchemesSnapshot = await _firestore
          .collection('govt_schemes')
          .where('isActive', isEqualTo: true)
          .get();
      
      if (govtSchemesSnapshot.docs.isNotEmpty) {
        return govtSchemesSnapshot.docs.map((doc) => GovtSchemeModel.fromSnapshot(doc)).toList();
      }

      // Fall back to schemes collection (from first document)
      final querySnapshot = await _firestore
          .collection('schemes')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GovtSchemeModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schemes: $e');
    }
  }

  // Get schemes by category
  Future<List<GovtSchemeModel>> getSchemesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('schemes')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GovtSchemeModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schemes by category: $e');
    }
  }

  // Check if user has already applied for a scheme
  Future<bool> hasUserAppliedForScheme(String userId, String schemeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .where('schemeId', isEqualTo: schemeId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get eligible schemes for user (from first document)
  Future<List<GovtSchemeModel>> getEligibleSchemes({
    required List<String> userCropTypes,
    required String userState,
  }) async {
    try {
      final allSchemes = await getAllSchemes();
      
      return allSchemes.where((scheme) {
        final isEligibleForCrops = scheme.isEligibleForCrops(userCropTypes);
        final isEligibleForState = scheme.isEligibleForState(userState);
        return isEligibleForCrops && isEligibleForState;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch eligible schemes: $e');
    }
  }

  // Get eligible schemes for user (alternative method from second document)
  Future<List<GovtSchemeModel>> getEligibleSchemesAlt(
    String userId,
    List<String> cropTypes,
    String? farmLocation, {
    String? overrideUserId,
    List<String>? userCropTypes,
    String? userLocation,
    bool showAll = true,
  }) async {
    try {
      final schemes = await getAllSchemes();

      if (showAll) {
        return schemes;
      }

      return schemes.where((scheme) {
        bool isEligible = true;

        if (userCropTypes != null && userCropTypes.isNotEmpty) {
          final cropEligible = scheme.eligibleCropTypes.contains('all') ||
              userCropTypes.any((crop) =>
                  scheme.eligibleCropTypes.contains(crop.toLowerCase()));
          isEligible = isEligible && cropEligible;
        }

        if (userLocation != null && userLocation.isNotEmpty) {
          final stateEligible = scheme.eligibleStates.contains('all') ||
              scheme.eligibleStates.any((state) =>
                  userLocation.toLowerCase().contains(state.toLowerCase()));
          isEligible = isEligible && stateEligible;
        }

        return isEligible;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch eligible schemes: $e');
    }
  }

  // Delete uploaded file (for cleanup)
  Future<void> deleteUploadedFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      // File might not exist or already deleted
      print('Error deleting file: $e');
    }
  }

  // Get application statistics for admin
  Future<Map<String, int>> getApplicationStatistics() async {
    try {
      final querySnapshot = await _firestore.collection('applications').get();
      
      final stats = <String, int>{
        'total': querySnapshot.docs.length,
        'submitted': 0,
        'underReview': 0,
        'approved': 0,
        'rejected': 0,
        'documentsPending': 0,
      };

      for (final doc in querySnapshot.docs) {
        final status = doc.data()['status'] as String;
        switch (status) {
          case 'ApplicationStatus.submitted':
            stats['submitted'] = (stats['submitted'] ?? 0) + 1;
            break;
          case 'ApplicationStatus.underReview':
            stats['underReview'] = (stats['underReview'] ?? 0) + 1;
            break;
          case 'ApplicationStatus.approved':
            stats['approved'] = (stats['approved'] ?? 0) + 1;
            break;
          case 'ApplicationStatus.rejected':
            stats['rejected'] = (stats['rejected'] ?? 0) + 1;
            break;
          case 'ApplicationStatus.documentsPending':
            stats['documentsPending'] = (stats['documentsPending'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch application statistics: $e');
    }
  }
}