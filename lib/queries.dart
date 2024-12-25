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
  mutation updateProduct(\$id: ID!, \$name: String!, \$price: Float!, \$image: String!) {
  updateProduct(id: \$id, name: \$name, price: \$price, image: \$image) {
    product {
      id
      name
      price
      image
    }
  }
}
""";

const String deleteProductMutation = """
  mutation deleteProduct(\$id: ID!) {
  deleteProduct(id: \$id) {
    success
    message
  }
}
""";
