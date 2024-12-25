 import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Import to handle file paths

// GraphQL Configuration
class GraphQLConfig {
  static final HttpLink httpLink = HttpLink('http://127.0.0.1:8000/graphql');

  static ValueNotifier<GraphQLClient> get client => ValueNotifier(
        GraphQLClient(
          cache: GraphQLCache(store: InMemoryStore()),
          link: httpLink,
        ),
      );
}

// GraphQL Query
const String fetchAllProducts = """
  query {
    allProducts {
      id
      name
      price
      image
    }
  }
""";

// GraphQL Mutation to Add Product
const String createProductMutation = """
  mutation createProduct(\$name: String!, \$price: Float!, \$image: String!) {
    createProduct(name: \$name, price: \$price, image: \$image) {
      product {
        id
        name
        price
        image
      }
    }
  }
""" ;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: GraphQLConfig.client,
      child: MaterialApp(
        title: 'GraphQL ListView',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: ProductListPage(),
      ),
    );
  }
}

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String name = '';
  double price = 0.0;
  String _imageUrl = '';

  // Method to pick image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageUrl = pickedFile.path;  // Update with the image path
      });
    }
  }

  @override
  void initState() {
    super.initState();
    name = _nameController.text;
    price = double.tryParse(_priceController.text) ?? 0.0;
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
                      if (_imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            children: [
                              Text('Image selected'),
                              Image.file(
                                File(_imageUrl),  // Display the image using the selected file path
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
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
        // Handle success
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
      onPressed: () {
        if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty && _imageUrl.isNotEmpty) {
          runMutation({
            'name': _nameController.text,
            'price': double.tryParse(_priceController.text) ?? 0.0,
            'image': _imageUrl,
          });
        }
      },
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
                ),
                builder: (QueryResult result, {FetchMore? fetchMore, Refetch? refetch}) {
                  if (result.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (result.hasException) {
                    debugPrint('GraphQL Error: ${result.exception.toString()}');
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
                    shrinkWrap: true, // Important for scrolling
                    physics: NeverScrollableScrollPhysics(), // Disable scrolling for nested ListView
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: product['image'] != null
                              ? Image.network(
                                  product['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported, size: 50),
                                )
                              : const Icon(Icons.image, size: 50),
                          title: Text(
                            product['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Price: \$${product['price']}'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            // Handle product click
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(product['name']),
                                content: Text('Price: \$${product['price']}'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
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