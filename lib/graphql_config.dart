// graphql_config.dart

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';


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
