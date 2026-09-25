import 'package:flutterflow_ai/flutterflow_ai.dart';

/// Query rows into page-local state, then render fields from each stored row.
void buildRowListState(App app) {
  app.supabase(url: 'https://example.supabase.co', anonKey: 'synthetic');
  final records = app.table(
    'records',
    fields: {
      'id': const PostgresTableField(
        int_,
        postgresType: 'int8',
        isPrimaryKey: true,
      ),
      'title': const PostgresTableField(string, postgresType: 'text'),
    },
  );
  app.page(
    'Records',
    route: '/',
    isInitial: true,
    state: {'rows': listOf(records)},
    onLoad: [
      PostgresQuery(records, outputAs: 'loadedRows', key: 'load-rows'),
      SetState('rows', ActionOutput('loadedRows'), key: 'store-rows'),
    ],
    body: Scaffold(
      body: ListView(
        name: 'StoredRows',
        source: State('rows'),
        itemBuilder: (row) => Text(row['title']),
      ),
    ),
  );
}
