import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:mmcm_hits/firebase_options.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/repositories/storage_repository.dart';

/// App-wide dependency registration.
class AppDependencies extends StatelessWidget {
  final Widget child;
  const AppDependencies({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // expose SDKs so anything below can context.read<...>()
        Provider<FirebaseAuth>.value(value: FirebaseAuth.instance),
        Provider<FirebaseFirestore>.value(value: FirebaseFirestore.instance),
        Provider<FirebaseDatabase>.value(value: FirebaseDatabase.instance),
        Provider<FirebaseStorage>.value(
          value: FirebaseStorage.instanceFor(
            app: Firebase.app(),
            bucket: DefaultFirebaseOptions.currentPlatform.storageBucket,
          ),
        ),

        ProxyProvider<FirebaseAuth, AuthRepository>(
          update: (_, auth, _) => AuthRepository(auth),
        ),
        ProxyProvider<FirebaseFirestore, UserRepository>(
          update: (_, firestore, _) => UserRepository(firestore),
        ),
        ProxyProvider2<FirebaseFirestore, FirebaseDatabase, RideRepository>(
          update: (_, firestore, realtimeDb, _) =>
              RideRepository(firestore, realtimeDb),
        ),
        ProxyProvider<FirebaseStorage, StorageRepository>(
          update: (_, storage, _) => StorageRepository(storage),
        ),
      ],
      child: child,
    );
  }
}
