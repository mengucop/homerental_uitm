import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingDetailPage extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String phone;
  final String email;

  const ListingDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.email,
  });

  void _confirmAndLaunch(BuildContext context, String title, VoidCallback launchFunction) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirm $title'),
        content: Text('Do you want to proceed to $title the owner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              launchFunction();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _launchPhone() {
    final uri = Uri.parse('tel:$phone');
    print('📞 Call button tapped: $phone');
    launchUrl(uri);
  }

  void _launchWhatsApp() {
    final uri = Uri.parse('https://wa.me/$phone');
    print('💬 WhatsApp tapped: $phone');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _launchEmail() {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Rental Inquiry from HomeRentalUiTM',
    );
    print('✉️ Email tapped: $email');
    launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng location = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RM $price",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  const Text(
                    "Location",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: location,
                        zoom: 16,
                      ),
                      markers: {
                        Marker(markerId: const MarkerId("location"), position: location),
                      },
                      liteModeEnabled: true,
                      zoomControlsEnabled: false,
                      onMapCreated: (_) {},
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Contact Owner:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.call),
                        label: const Text("Call"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _confirmAndLaunch(context, 'call', _launchPhone),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.message),
                        label: const Text("WhatsApp"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _confirmAndLaunch(context, 'WhatsApp', _launchWhatsApp),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.email),
                        label: const Text("Email"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _confirmAndLaunch(context, 'email', _launchEmail),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
