import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/constants.dart';

class DetectedImagesPage extends StatelessWidget {
  const DetectedImagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user's ID
    User? user = FirebaseAuth.instance.currentUser;
    String userId = user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Detected Images",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
            letterSpacing: 1.25,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          color: Colors.white,
          onPressed: () {
            // _scaffoldKey.currentState!.openDrawer();
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
        elevation: 0.0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('detectedResult')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error retrieving images'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No detected images found'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((document) {
              Map<String, dynamic> data =
                  (document.data() as Map<String, dynamic>);
              String imageUrl = data['imageUrl'];
              String imageName = data['name'];
              String label = data['detectedLabel'];
              bool isPlasticDetected = data['isPlasticDetected'];
              double confidence = data['detectedValue'];
              String? city = data['city'];
              String? country = data['country'];
              String? street = data['street'];
              String confidencePercentage =
                  (confidence * 100).toStringAsFixed(2);

              return GestureDetector(
                onTap: () {
                  // Navigate to the image details page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageDetailsPage(
                        imageUrl: imageUrl,
                        imageName: imageName,
                        isPlasticDetected: isPlasticDetected,
                        documentId: document.id, // Pass the document ID
                      ),
                    ),
                  );
                },
                child: Card(
                  color: Colors.white,
                  elevation: 3.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          child: InteractiveViewer(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double
                                  .infinity, // Set the image width to the width of the card
                              height: 150.0,
                            ),
                          ),
                          onLongPress: () {
                            // Handle long press event if needed
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          imageName,
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Confidence Level:",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '$confidencePercentage %',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w300,
                                color: isPlasticDetected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          "Class: $label",
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        country != null
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  country != null
                                      ? Expanded(
                                          child: Text(
                                            "Detected in  $country",
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w300,
                                              color: isPlasticDetected
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        )
                                      : const SizedBox(),
                                  city != null
                                      ? Expanded(
                                          child: Text(
                                            "in $city",
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w300,
                                              color: isPlasticDetected
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        )
                                      : const SizedBox(),
                                  street != null
                                      ? Expanded(
                                          child: Text(
                                            "at Street $street",
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w300,
                                              color: isPlasticDetected
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        )
                                      : const SizedBox(),
                                ],
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
class ImageDetailsPage extends StatelessWidget {
  final String imageUrl;
  final String imageName;
  final bool isPlasticDetected;
  final String documentId;

  const ImageDetailsPage({
    Key? key,
    required this.imageUrl,
    required this.imageName,
    required this.isPlasticDetected,
    required this.documentId,
  }) : super(key: key);

  Future<void> _deleteImage(BuildContext context) async {
    final scaffoldContext = context;
    try {
      await FirebaseFirestore.instance
          .collection('detectedResult')
          .doc(documentId)
          .delete();
      Navigator.pop(scaffoldContext); // Go back to the previous page
    } catch (e) {
      // Handle the error if deletion fails
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Error',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text('Failed to delete image.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),  ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Details'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    // Open a zoomable view of the image
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ZoomableImage(imageUrl: imageUrl),
                      ),
                    );
                  },
                  child: Hero(
                    tag: imageUrl, // Unique tag for the Hero widget
                    child: InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(20.0), // Adjust this margin as needed
                      minScale: 1.0,
                      maxScale: 4.0, // Adjust the maximum zoom level as needed
                      scaleEnabled: true,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  imageName,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () => _deleteImage(context),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZoomableImage extends StatelessWidget {
  final String imageUrl;

  const ZoomableImage({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoomable Image'),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Hero(
            tag: imageUrl, // Use the same tag as in ImageDetailsPage
            child: InteractiveViewer(
              boundaryMargin: EdgeInsets.all(20.0), // Adjust this margin as needed
              minScale: 1.0,
              maxScale: 4.0, // Adjust the maximum zoom level as needed
              scaleEnabled: true,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

