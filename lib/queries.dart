// graphql_queries.dart

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

const String createProductMutation = """
  mutation CreateProduct(\$name: String!, \$price: Float!, \$image: String) {
  createProduct(name: \$name, price: \$price, image: \$image) {
    product {
      id
      name
      price
      image  # Returns the base64 image string
    }
  }
}
""";

const String updateProductMutation = """
  mutation UpdateProduct(\$id: Int!, \$name: String, \$price: Float, \$image: String) {
  updateProduct(id: \$id, name: \$name, price: \$price, image: \$image) {
    product {
      ids
      name
      price
      image  # Returns the updated base64 image string
    }
  }
}
""";

const String deleteProductMutation = """
  mutation deleteProduct(\$id: Int!) {
    deleteProduct(id: \$id) {
      success
    }
  }
""";
