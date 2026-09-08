import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const appName = 'عالم بيانات لف المحركات';
const ownerName = 'م. محمد سيد';
const ownerPhone = '01066432680';
const copyrightNotice = 'تمت البرمجة والتطوير والإنشاء من خلال م. محمد سيد';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: key);
  }
  runApp(const MotorApp());
}

class MotorApp extends StatelessWidget {
  const MotorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: appName,
        locale: const Locale('ar'),
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Supabase.instance.isInitialized) return const ConfigPage();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) => Supabase.instance.client.auth.currentSession == null
          ? const LoginPage()
          : const HomePage(),
    );
  }
}

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(appName)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'قاعدة البيانات غير مهيأة.\nشغّل التطبيق مع SUPABASE_URL و SUPABASE_ANON_KEY.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _msg('أدخل البريد الإلكتروني وكلمة المرور.');
      return;
    }
    setState(() => busy = true);
    try {
      if (register) {
        final response = await Supabase.instance.client.auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );
        _msg(response.session == null
            ? 'تم إنشاء الحساب. تحقق من بريدك الإلكتروني إذا كان التأكيد مطلوبًا.'
            : 'تم إنشاء الحساب بنجاح.');
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      _msg(e.message);
    } catch (e) {
      _msg('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _msg(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.electric_bolt, size: 70),
                  const SizedBox(height: 12),
                  const Text(appName, textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'جارٍ التنفيذ...' : register ? 'إنشاء الحساب' : 'تسجيل الدخول')),
                  TextButton(onPressed: busy ? null : () => setState(() => register = !register), child: Text(register ? 'لدي حساب بالفعل — تسجيل الدخول' : 'إنشاء حساب جديد')),
                ],
              ),
            ),
          ),
        ),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  static const pages = <Widget>[Dashboard(), MotorsPage(), AddMotorPage(), AboutPage()];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(appName), actions: [IconButton(onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout))]),
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.search), label: 'السجل'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'إضافة'),
            NavigationDestination(icon: Icon(Icons.info_outline), label: 'حول التطبيق'),
          ],
        ),
      );
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  Future<Map<String, dynamic>> load() async {
    final response = await Supabase.instance.client.rpc('get_motor_statistics');
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: load(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل الإحصائيات: ${snapshot.error}'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('لوحة الإحصائيات', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _card('إجمالي المحركات', data['total'] ?? 0, Icons.electric_bolt),
              _card('المسجل اليوم', data['today'] ?? 0, Icons.today),
              _card('هذا الشهر', data['this_month'] ?? 0, Icons.calendar_month),
              const SizedBox(height: 8),
              const Text('يمكنك البحث في السجل أو نسخ بيانات موتور سابق كأساس لموتور جديد.'),
            ],
          );
        },
      );

  Widget _card(String title, dynamic value, IconData icon) => Card(child: ListTile(leading: Icon(icon), title: Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), subtitle: Text(title)));
}

class MotorsPage extends StatefulWidget {
  const MotorsPage({super.key});

  @override
  State<MotorsPage> createState() => _MotorsPageState();
}

class _MotorsPageState extends State<MotorsPage> {
  final q = TextEditingController();
  final type = TextEditingController();
  final power = TextEditingController();
  final speed = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    search();
  }

  @override
  void dispose() {
    q.dispose();
    type.dispose();
    power.dispose();
    speed.dispose();
    super.dispose();
  }

  Future<void> search() async {
    setState(() => loading = true);
    try {
      final response = await Supabase.instance.client.rpc('search_motors', params: {
        'search_text': q.text.trim().isEmpty ? null : q.text.trim(),
        'filter_type': type.text.trim().isEmpty ? null : type.text.trim(),
        'filter_power': double.tryParse(power.text.trim()),
        'filter_speed': int.tryParse(speed.text.trim()),
      });
      rows = List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر البحث: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(controller: q, onSubmitted: (_) => search(), decoration: const InputDecoration(labelText: 'بحث عام', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: TextField(controller: type, decoration: const InputDecoration(labelText: 'النوع'))), const SizedBox(width: 6), Expanded(child: TextField(controller: power, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القدرة'))), const SizedBox(width: 6), Expanded(child: TextField(controller: speed, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السرعة')))]),
              const SizedBox(height: 8),
              FilledButton.icon(onPressed: loading ? null : search, icon: const Icon(Icons.search), label: const Text('بحث')),
            ]),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? const Center(child: Text('لا توجد سجلات مطابقة'))
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final motor = rows[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text('${motor['motor_code'] ?? '-'}'),
                              subtitle: Text('${motor['motor_type'] ?? '-'} • ${motor['motor_power'] ?? '-'} • ${motor['motor_speed'] ?? '-'}'),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MotorDetailsPage(motor: motor))),
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
}

class MotorDetailsPage extends StatelessWidget {
  const MotorDetailsPage({super.key, required this.motor});
  final Map<String, dynamic> motor;

  @override
  Widget build(BuildContext context) {
    const fields = {
      'نوع المحرك': 'motor_type',
      'قدرة المحرك': 'motor_power',
      'وحدة القدرة': 'motor_power_unit',
      'سرعة المحرك': 'motor_speed',
      'خطوة اللف': 'winding_step',
      'قطر السلك': 'wire_diameter',
      'عدد الملفات': 'coil_count',
      'طريقة اللحام': 'welding_method',
      'التوصيل': 'connection_type',
      'القائم بالعمل': 'technician_name',
    };
    return Scaffold(
      appBar: AppBar(title: Text('${motor['motor_code'] ?? '-'}')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final entry in fields.entries) Card(child: ListTile(title: Text(entry.key), subtitle: Text('${motor[entry.value] ?? '-'}'))),
          Card(child: ListTile(title: const Text('تاريخ التسجيل'), subtitle: Text(_date(motor['created_at'])))),
          FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMotorPage(template: motor))), icon: const Icon(Icons.copy), label: const Text('استخدام البيانات كأساس لموتور جديد')),
        ],
      ),
    );
  }

  static String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null ? '-' : DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }
}

class AddMotorPage extends StatefulWidget {
  const AddMotorPage({super.key, this.template});
  final Map<String, dynamic>? template;

  @override
  State<AddMotorPage> createState() => _AddMotorPageState();
}

class _AddMotorPageState extends State<AddMotorPage> {
  final formKey = GlobalKey<FormState>();
  static const fields = [
    ['motor_type', 'نوع المحرك'],
    ['motor_power', 'قدرة المحرك'],
    ['motor_power_unit', 'وحدة القدرة'],
    ['motor_speed', 'سرعة المحرك'],
    ['winding_step', 'خطوة اللف'],
    ['wire_diameter', 'قطر السلك'],
    ['coil_count', 'عدد الملفات'],
    ['welding_method', 'طريقة اللحام'],
    ['connection_type', 'التوصيل'],
    ['technician_name', 'القائم بالعمل على المحرك'],
  ];
  late final Map<String, TextEditingController> controllers;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    controllers = {for (final field in fields) field[0]: TextEditingController(text: widget.template?[field[0]]?.toString() ?? '')};
  }

  @override
  void dispose() {
    for (final controller in controllers.values) controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final data = <String, dynamic>{};
      for (final field in fields) {
        final value = controllers[field[0]]!.text.trim();
        if (value.isNotEmpty) data[field[0]] = field[0] == 'coil_count' ? int.tryParse(value) : value;
      }
      await Supabase.instance.client.from('motors').insert(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات المحرك بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.template == null ? 'إضافة موتور' : 'موتور جديد من سجل سابق')),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final field in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: controllers[field[0]],
                    keyboardType: field[0] == 'coil_count' ? TextInputType.number : TextInputType.text,
                    decoration: InputDecoration(labelText: field[1], border: const OutlineInputBorder()),
                    validator: field[0] == 'motor_type' ? (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null : null,
                  ),
                ),
              const Text('التاريخ والوقت يتم تسجيلهما تلقائيًا من قاعدة البيانات.'),
              const SizedBox(height: 12),
              FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'جارٍ الحفظ...' : 'حفظ المحرك')),
            ],
          ),
        ),
      );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.electric_bolt, size: 80),
          const SizedBox(height: 16),
          const Text(appName, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(ownerName, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('هاتف: $ownerPhone', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          const Text(copyrightNotice, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('© جميع حقوق الملكية الفكرية محفوظة', textAlign: TextAlign.center),
        ],
      );
}
