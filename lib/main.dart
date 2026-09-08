import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    await Supabase.initialize(url: url, anonKey: key);
  }

  runApp(const MotorApp());
}

class MotorApp extends StatelessWidget {
  const MotorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      locale: const Locale('ar'),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Supabase.instance.isInitialized) {
      return const ConfigPage();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        return session == null ? const LoginPage() : const HomePage();
      },
    );
  }
}

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'قاعدة البيانات غير مهيأة.\nشغّل التطبيق مع SUPABASE_URL و SUPABASE_ANON_KEY.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
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
        _msg(
          response.session == null
              ? 'تم إنشاء الحساب. أكمل تأكيد البريد إن كان مطلوبًا ثم سجّل الدخول.'
              : 'تم إنشاء الحساب بنجاح.',
        );
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
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.electric_bolt, size: 64),
                  const SizedBox(height: 10),
                  const Text(
                    appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(
                      busy
                          ? 'جارٍ التنفيذ…'
                          : register
                              ? 'إنشاء الحساب'
                              : 'دخول',
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => register = !register),
                    child: Text(
                      register
                          ? 'لدي حساب بالفعل — تسجيل الدخول'
                          : 'إنشاء حساب جديد',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = <Widget>[
      Dashboard(),
      MotorsPage(),
      AddMotorPage(),
      AboutPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            appName,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              label: 'السجل',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'إضافة',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              label: 'حول التطبيق',
            ),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final response = await Supabase.instance.client.rpc(
        'get_motor_statistics',
      );
      stats = Map<String, dynamic>.from(response as Map);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل الإحصائيات: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = stats ?? <String, dynamic>{};

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'لوحة الإحصائيات',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('بيانات مباشرة من قاعدة البيانات.'),
          const SizedBox(height: 18),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    'إجمالي المحركات',
                    data['total'] ?? 0,
                    Icons.electric_bolt,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    'اليوم',
                    data['today'] ?? 0,
                    Icons.today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _StatCard(
              'هذا الشهر',
              data['this_month'] ?? 0,
              Icons.calendar_month,
            ),
            const SizedBox(height: 12),
            _GroupCard('حسب النوع', data['by_type']),
            _GroupCard('حسب القدرة', data['by_power']),
            _GroupCard('حسب السرعة', data['by_speed']),
            _GroupCard('حسب الفني', data['by_technician']),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final dynamic value;
  final IconData icon;

  const _StatCard(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String title;
  final dynamic data;

  const _GroupCard(this.title, this.data);

  @override
  Widget build(BuildContext context) {
    final rows = data is List ? data : const <dynamic>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...rows.take(8).map<Widget>(
              (row) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('${row['label'] ?? ''}'),
                trailing: Text('${row['count'] ?? 0}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

  bool loading = false;
  List<Map<String, dynamic>> rows = [];

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
      final response = await Supabase.instance.client.rpc(
        'search_motors',
        params: {
          'search_text': q.text.trim().isEmpty ? null : q.text.trim(),
          'filter_type': type.text.trim().isEmpty ? null : type.text.trim(),
          'filter_power': double.tryParse(power.text.trim()),
          'filter_speed': int.tryParse(speed.text.trim()),
        },
      );

      rows = List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر البحث: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void clearFilters() {
    q.clear();
    type.clear();
    power.clear();
    speed.clear();
    search();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: q,
            decoration: const InputDecoration(
              labelText: 'بحث عام (كود / نوع / قدرة / سرعة / فني)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _filter(type, 'نوع')),
              const SizedBox(width: 8),
              Expanded(child: _filter(power, 'القدرة', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _filter(speed, 'السرعة', numeric: true)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading ? null : search,
                  icon: const Icon(Icons.search),
                  label: const Text('بحث'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: clearFilters,
                icon: const Icon(Icons.clear),
                tooltip: 'مسح الفلاتر',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? const Center(child: Text('لا توجد نتائج.'))
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final motor = rows[index];
                          return Card(
                            child: ListTile(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MotorDetailsPage(motor: motor),
                                ),
                              ),
                              title: Text('${motor['motor_code']}'),
                              subtitle: Text(
                                '${motor['motor_type']} • '
                                '${motor['motor_power']} '
                                '${motor['motor_power_unit']} • '
                                '${motor['motor_speed']} RPM',
                              ),
                              trailing: const Icon(Icons.chevron_left),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filter(
    TextEditingController controller,
    String label, {
    bool numeric = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class MotorDetailsPage extends StatelessWidget {
  final Map<String, dynamic> motor;

  const MotorDetailsPage({super.key, required this.motor});

  @override
  Widget build(BuildContext context) {
    final fields = <List<dynamic>>[
      ['كود المحرك', motor['motor_code']],
      ['نوع المحرك', motor['motor_type']],
      ['القدرة', '${motor['motor_power']} ${motor['motor_power_unit'] ?? ''}'],
      ['السرعة', '${motor['motor_speed']} RPM'],
      ['خطوة اللف', motor['winding_step']],
      ['قطر السلك', motor['wire_diameter']],
      ['عدد الملفات', motor['coil_count']],
      ['طريقة اللحام', motor['welding_method']],
      ['التوصيل', motor['connection_type']],
      ['القائم بالعمل', motor['technician_name']],
      ['تاريخ الإنشاء', _date(motor['created_at'])],
      ['آخر تحديث', _date(motor['updated_at'])],
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('${motor['motor_code']}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...fields.map(
              (field) => Card(
                child: ListTile(
                  title: Text(field[0].toString()),
                  subtitle: Text(field[1]?.toString() ?? '—'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMotorPage(initialMotor: motor),
                ),
              ),
              icon: const Icon(Icons.copy),
              label: const Text('استخدام البيانات كأساس لموتور جديد'),
            ),
          ],
        ),
      ),
    );
  }

  static String _date(dynamic value) {
    if (value == null) return '—';
    try {
      return DateFormat('yyyy/MM/dd HH:mm:ss')
          .format(DateTime.parse(value.toString()).toLocal());
    } catch (_) {
      return '$value';
    }
  }
}

class AddMotorPage extends StatefulWidget {
  final Map<String, dynamic>? initialMotor;

  const AddMotorPage({super.key, this.initialMotor});

  @override
  State<AddMotorPage> createState() => _AddMotorPageState();
}

class _AddMotorPageState extends State<AddMotorPage> {
  final fields = List.generate(9, (_) => TextEditingController());
  bool saving = false;

  static const labels = [
    'نوع المحرك',
    'قدرة المحرك',
    'سرعة المحرك',
    'خطوة اللف',
    'قطر السلك',
    'عدد الملفات',
    'طريقة اللحام',
    'التوصيل',
    'القائم بالعمل على المحرك',
  ];

  @override
  void initState() {
    super.initState();
    final motor = widget.initialMotor;
    if (motor == null) return;

    fields[0].text = '${motor['motor_type'] ?? ''}';
    fields[1].text = '${motor['motor_power'] ?? ''}';
    fields[2].text = '${motor['motor_speed'] ?? ''}';
    fields[3].text = '${motor['winding_step'] ?? ''}';
    fields[4].text = '${motor['wire_diameter'] ?? ''}';
    fields[5].text = '${motor['coil_count'] ?? ''}';
    fields[6].text = '${motor['welding_method'] ?? ''}';
    fields[7].text = '${motor['connection_type'] ?? ''}';
    fields[8].text = '${motor['technician_name'] ?? ''}';
  }

  @override
  void dispose() {
    for (final controller in fields) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (fields.any((field) => field.text.trim().isEmpty)) {
      _msg('من فضلك أكمل جميع البيانات المطلوبة.');
      return;
    }

    final power = fields[1].text.trim();
    final speed = int.tryParse(fields[2].text.trim());
    final wireDiameter = fields[4].text.trim();
    final coilCount = int.tryParse(fields[5].text.trim());

    if (speed == null || coilCount == null || coilCount <= 0) {
      _msg('تحقق من سرعة المحرك وعدد الملفات.');
      return;
    }

    setState(() => saving = true);

    try {
      await Supabase.instance.client.from('motors').insert({
        'motor_type': fields[0].text.trim(),
        'motor_power': power,
        'motor_speed': speed,
        'winding_step': fields[3].text.trim(),
        'wire_diameter': wireDiameter,
        'coil_count': coilCount,
        'welding_method': fields[6].text.trim(),
        'connection_type': fields[7].text.trim(),
        'technician_name': fields[8].text.trim(),
      });

      if (!mounted) return;
      _msg('تم حفظ بيانات المحرك بنجاح. تم إنشاء الكود والتاريخ تلقائيًا.');
      _clearForm();
    } on PostgrestException catch (e) {
      _msg('تعذر حفظ البيانات: ${e.message}');
    } catch (e) {
      _msg('حدث خطأ أثناء الحفظ: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _clearForm() {
    for (final controller in fields) {
      controller.clear();
    }
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.initialMotor == null
                ? 'إضافة موتور جديد'
                : 'موتور جديد من سجل سابق',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'الكود والتاريخ والوقت يتم إنشاؤها تلقائيًا من قاعدة البيانات.',
          ),
          const SizedBox(height: 18),
          ...List.generate(
            labels.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: fields[index],
                keyboardType: index == 1 || index == 2 || index == 4 || index == 5
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                inputFormatters: index == 2 || index == 5
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                decoration: InputDecoration(
                  labelText: labels[index],
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(saving ? 'جارٍ الحفظ…' : 'حفظ بيانات المحرك'),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.electric_bolt, size: 72),
          const SizedBox(height: 12),
          const Text(
            appName,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Text(
                    'بيانات الملكية',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('المالك: $ownerName'),
                  Text('الهاتف: $ownerPhone'),
                  SizedBox(height: 8),
                  Text(copyrightNotice),
                  Text('© جميع حقوق الملكية الفكرية محفوظة'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
