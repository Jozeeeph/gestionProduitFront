import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'graphql_config.dart';
import 'queries.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _base64Image = ''; // Store base64 string of the image

  // Helper function to pick and convert image to base64
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final File file = File(result.files.single.path!);
      final List<int> imageBytes = await file.readAsBytes();
      setState(() {
        _base64Image = base64Encode(imageBytes); // Convert image bytes to base64
      });
    }
  }

  // Method to handle form submission and mutation
  void _handleProductSubmit(RunMutation runMutation) {
    if (_nameController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _base64Image.isNotEmpty) {
      runMutation({
        'name': _nameController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'image': _base64Image,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  // Method to build Image Widget from base64
  Widget _buildImage(String base64Image) {
    try {
      return Image.memory(
        base64Decode(base64Image),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported, size: 50),
      );
    } catch (e) {
      return const Icon(Icons.image_not_supported, size: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Add Product Form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Product Name'),
                  ),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('Pick Image'),
                      ),
                      if (_base64Image.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            children: [
                              const Text('Image selected'),
                              _buildImage(_base64Image), // Show base64 image
                            ],
                          ),
                        ),
                    ],
                  ),
                  Mutation(
                    options: MutationOptions(
                      document: gql(createProductMutation),
                      onCompleted: (dynamic resultData) {
                        if (resultData != null) {
                          print('Product added: ${resultData['createProduct']['product']['name']}');
                        }
                      },
                    ),
                    builder: (RunMutation runMutation, QueryResult? result) {
                      if (result?.hasException ?? false) {
                        return Center(
                          child: Text(
                            'Error: ${result!.exception.toString()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      return ElevatedButton(
                        onPressed: () => _handleProductSubmit(runMutation),
                        child: const Text('Add Product'),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Display Products List
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Query(
                options: QueryOptions(
                  document: gql(fetchAllProducts),
                  fetchPolicy: FetchPolicy.noCache,
                ),
                builder: (QueryResult result, {FetchMore? fetchMore, Refetch? refetch}) {
                  if (result.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (result.hasException) {
                    return Center(
                      child: Text(
                        'Error: ${result.exception.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final List? products = result.data?['allProducts'];
                  if (products == null || products.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: product['image'] != null
                              ? _buildImage(product['image']) // Show image from base64
                              : const Icon(Icons.image, size: 50),
                          title: Text(
                            product['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Price: \$${product['price']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _nameController.text = product['name'];
                                  _priceController.text = product['price'].toString();
                                  _base64Image = product['image'] ?? '';
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Update Product'),
                                      content: Mutation(
                                        options: MutationOptions(
                                          document: gql(updateProductMutation),
                                          onCompleted: (dynamic resultData) {
                                            refetch!();
                                            Navigator.pop(context);
                                          },
                                        ),
                                        builder: (RunMutation runMutation, QueryResult? result) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: _nameController,
                                                decoration: const InputDecoration(labelText: 'Product Name'),
                                              ),
                                              TextField(
                                                controller: _priceController,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(labelText: 'Price'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  runMutation({
                                                    'id': product['id'],
                                                    'name': _nameController.text,
                                                    'price': double.tryParse(_priceController.text) ?? 0.0,
                                                    'image': _base64Image,
                                                  });
                                                },
                                                child: const Text('Update'),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Delete Product'),
                                        content: const Text('Are you sure you want to delete this product?'),
                                        actions: [
                                          Mutation(
                                            options: MutationOptions(
                                              document: gql(deleteProductMutation),
                                              onCompleted: (dynamic resultData) {
                                                if (resultData != null &&
                                                    resultData['deleteProduct']['success']) {
                                                  refetch!(); // Refresh the product list
                                                  Navigator.pop(context); // Close the dialog
                                                }
                                              },
                                            ),
                                            builder: (RunMutation runMutation, QueryResult? result) {
                                              return Row(
                                                children: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context), // Cancel action
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      runMutation({'id': product['id']}); // Execute delete mutation
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
