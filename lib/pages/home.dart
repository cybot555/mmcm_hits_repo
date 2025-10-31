import 'package:flutter/material.dart';
import 'package:mmcm_hits/pages/home_pages/create_ride_section.dart';
import 'package:mmcm_hits/pages/home_pages/driver_requests_section.dart';
import 'package:mmcm_hits/pages/home_pages/passenger_rides_section.dart';
import 'package:mmcm_hits/pages/home_pages/profile_section.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/home_viewmodel.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    final userRepository = context.read<UserRepository>();

    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        authRepository,
        userRepository,
        uid: uid,
      )
        ..initialise(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  String _titleFor(HomeViewModel vm) {
    if (vm.currentIndex == 0) return 'Profile';
    if (vm.currentIndex == 1 && vm.role == 'Hitcher') {
      return 'Available Rides';
    }
    if (vm.currentIndex == 1 && vm.role == 'Driver') {
      return 'Ride Requests';
    }
    if (vm.currentIndex == 2 && vm.role == 'Driver') {
      return 'Create Ride';
    }
    return '';
  }

  String _subtitleFor(HomeViewModel vm) {
    if (vm.currentIndex == 0) {
      return 'Build your profile for MMCM students to see!';
    }
    if (vm.currentIndex == 1 && vm.role == 'Hitcher') {
      return 'Find available rides going along your destination.';
    }
    if (vm.currentIndex == 1 && vm.role == 'Driver') {
      return 'See requests on posted shared ride!';
    }
    if (vm.currentIndex == 2 && vm.role == 'Driver') {
      return 'Post a ride for others to join.';
    }
    return '';
  }

  List<Widget> _buildPages(HomeViewModel vm) {
    final uid = vm.uid;
    return [
      ProfileSection(
        uid: uid,
        role: vm.role,
        onLogout: vm.logout,
      ),
      if (vm.role == 'Hitcher')
        const PassengerRidesSection()
      else
        const DriverRequestsSection(),
      if (vm.role == 'Driver') const MapPage(),
    ];
  }

  BottomNavigationBar _buildBottomNav(HomeViewModel vm) {
    final isDriver = vm.role == 'Driver';
    return BottomNavigationBar(
      backgroundColor: isDriver
          ? const Color.fromARGB(255, 195, 255, 198)
          : const Color.fromARGB(255, 192, 237, 255),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black38,
      currentIndex: vm.currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: vm.changeTab,
      items: [
        const BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 0.5),
            child: SizedBox(
              height: 30,
              child: Image(
                image: AssetImage('assets/icons/profile.png'),
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
            ),
          ),
          label: 'PROFILE',
        ),
        if (vm.role == 'Hitcher')
          const BottomNavigationBarItem(
            icon: Image(
              image: AssetImage('assets/icons/rides.png'),
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
            label: 'RIDES',
          )
        else
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: SizedBox(
                height: 30,
                child: Image(
                  image: AssetImage('assets/icons/requests.png'),
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            label: 'REQUESTS',
          ),
        if (vm.role == 'Driver')
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: SizedBox(
                height: 30,
                child: Image(
                  image: AssetImage('assets/icons/createride.png'),
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            label: 'CREATE',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, _) {
        if (!viewModel.hasLoadedInitialUser) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (viewModel.user == null) {
          return _MissingProfileView(
            message: viewModel.errorMessage ??
                'We could not find your profile information.',
            onLogout: viewModel.logout,
          );
        }

        final isDriver = viewModel.role == 'Driver';
        final themeColor = isDriver
            ? const Color.fromARGB(255, 195, 255, 198)
            : const Color.fromARGB(255, 192, 237, 255);
        final pages = _buildPages(viewModel);
        final title = _titleFor(viewModel);
        final subtitle = _subtitleFor(viewModel);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: themeColor,
            elevation: 0,
            toolbarHeight: 85,
            title: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: pages[viewModel.currentIndex],
          bottomNavigationBar: _buildBottomNav(viewModel),
        );
      },
    );
  }
}

class _MissingProfileView extends StatelessWidget {
  const _MissingProfileView({
    required this.message,
    required this.onLogout,
  });

  final String message;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  onLogout();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
