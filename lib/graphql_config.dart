import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLConfig {
  static HttpLink httpLink = HttpLink('http://127.0.0.1:8000/graphql'); // Your GraphQL endpoint

  static ValueNotifier<GraphQLClient> get client => ValueNotifier(
    GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: httpLink,
    ),
  );
}
