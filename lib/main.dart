Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Ya no dependemos del .env para inicializar Supabase
    await Supabase.initialize(
      url: 'https://hagqqtigamcglgdeszaj.supabase.co',
      anonKey: 'sb_publishable__6UQ5OJMtttyaiw-Q9oE0A_tO20hrLE',
    );

    runApp(const MyApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Error crítico al iniciar:\n$e', 
              style: const TextStyle(color: Colors.red, fontSize: 16)
            ),
          ),
        ),
      ),
    ));
  }
}