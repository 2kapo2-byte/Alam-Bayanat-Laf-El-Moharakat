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
  if (url.isNotEmpty && key.isNotEmpty) await Supabase.initialize(url: url, anonKey: key);
  runApp(const MotorApp());
}

class MotorApp extends StatelessWidget {
  const MotorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: appName,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    locale: const Locale('ar'), home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Supabase.instance.isInitialized) return const ConfigPage();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (_, __) => Supabase.instance.client.auth.currentSession == null ? const LoginPage() : const HomePage(),
    );
  }
}

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});
  @override
  Widget build(BuildContext context) => const Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(body: Center(child: Padding(padding: EdgeInsets.all(24), child: Text(
      'قاعدة البيانات غير مهيأة.\nشغّل التطبيق مع SUPABASE_URL و SUPABASE_ANON_KEY.', textAlign: TextAlign.center,
    )))),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(); final password = TextEditingController();
  bool register = false, busy = false;
  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) { _msg('أدخل البريد الإلكتروني وكلمة المرور.'); return; }
    setState(() => busy = true);
    try {
      if (register) {
        final r = await Supabase.instance.client.auth.signUp(email: email.text.trim(), password: password.text);
        _msg(r.session == null ? 'تم إنشاء الحساب. أكمل تأكيد البريد إن كان مطلوبًا ثم سجّل الدخول.' : 'تم إنشاء الحساب.');
      } else {
        await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } on AuthException catch (e) { _msg(e.message); }
    catch (e) { _msg('حدث خطأ: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  void _msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Icon(Icons.electric_bolt, size: 64), SizedBox(height: 10),
        Text(appName, textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        SizedBox(height: 24),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined))),
        SizedBox(height: 12),
        TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline))),
        SizedBox(height: 16),
        // The controls below intentionally depend on the current register state.
        _AuthButton(),
      ],),
    ))),
  ));
}

class _AuthButton extends StatelessWidget {
  const _AuthButton();
  @override Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_LoginPageState>()!;
    return Column(children: [
      FilledButton(onPressed: state.busy ? null : state.submit, child: Text(state.busy ? 'جارٍ التنفيذ…' : state.register ? 'إنشاء الحساب' : 'دخول')),
      TextButton(onPressed: state.busy ? null : () => state.setState(() => state.register = !state.register), child: Text(state.register ? 'لدي حساب بالفعل — تسجيل الدخول' : 'إنشاء حساب جديد')),
    ]);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int index = 0;
  @override Widget build(BuildContext context) {
    final pages = [const Dashboard(), const MotorsPage(), const AddMotorPage(), const AboutPage()];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text(appName, style: TextStyle(fontWeight: FontWeight.bold)), actions: [
        IconButton(onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout), tooltip: 'تسجيل الخروج'),
      ]), body: pages[index],
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.search), label: 'السجل'),
        NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'إضافة'),
        NavigationDestination(icon: Icon(Icons.info_outline), label: 'حول التطبيق'),
      ]),
    ));
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? stats;
  bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() => loading = true);
    try { stats = Map<String, dynamic>.from(await Supabase.instance.client.rpc('get_motor_statistics') as Map); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل الإحصائيات: $e'))); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override Widget build(BuildContext context) {
    final s = stats ?? {};
    return RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('لوحة الإحصائيات', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('بيانات مباشرة من قاعدة البيانات.'), const SizedBox(height: 18),
      if (loading) const Center(child: CircularProgressIndicator()) else ...[
        Row(children: [Expanded(child: _Stat('إجمالي المحركات', s['total'] ?? 0, Icons.electric_bolt)), const SizedBox(width: 10), Expanded(child: _Stat('اليوم', s['today'] ?? 0, Icons.today))]),
        const SizedBox(height: 10), _Stat('هذا الشهر', s['this_month'] ?? 0, Icons.calendar_month), const SizedBox(height: 12),
        _Group('حسب النوع', s['by_type']), _Group('حسب القدرة', s['by_power']), _Group('حسب السرعة', s['by_speed']), _Group('حسب الفني', s['by_technician']),
      ],
    ]));
  }
}
class _Stat extends StatelessWidget { final String title; final dynamic value; final IconData icon; const _Stat(this.title, this.value, this.icon); @override Widget build(BuildContext c) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, size: 30), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(title)])]))); }
class _Group extends StatelessWidget { final String title; final dynamic data; const _Group(this.title, this.data); @override Widget build(BuildContext c) { final rows = data is List ? data : const []; return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), ...rows.take(8).map<Widget>((r) => ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text('${r['label'] ?? ''}'), trailing: Text('${r['count'] ?? 0}')))]))); } }

class MotorsPage extends StatefulWidget { const MotorsPage({super.key}); @override State<MotorsPage> createState() => _MotorsPageState(); }
class _MotorsPageState extends State<MotorsPage> {
  final q=TextEditingController(), type=TextEditingController(), power=TextEditingController(), speed=TextEditingController(); bool loading=false; List<Map<String,dynamic>> rows=[];
  Future<void> search() async { setState(() => loading=true); try { final r=await Supabase.instance.client.rpc('search_motors', params: {'search_text': q.text.trim().isEmpty?null:q.text.trim(),'filter_type':type.text.trim().isEmpty?null:type.text.trim(),'filter_power':double.tryParse(power.text.trim()),'filter_speed':int.tryParse(speed.text.trim())}); rows=List<Map<String,dynamic>>.from(r as List); } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر البحث: $e'))); } finally {if(mounted)setState(()=>loading=false);} }
  @override void initState(){super.initState(); search();}
  @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(16),child:Column(children:[
    TextField(controller:q,decoration:const InputDecoration(labelText:'بحث عام (كود / نوع / قدرة / سرعة / فني)',border:OutlineInputBorder(),prefixIcon:Icon(Icons.search))),const SizedBox(height:10),
    Row(children:[Expanded(child:_f(type,'نوع')),const SizedBox(width:8),Expanded(child:_f(power,'القدرة')),const SizedBox(width:8),Expanded(child:_f(speed,'السرعة'))]),const SizedBox(height:10),
    Row(children:[Expanded(child:FilledButton.icon(onPressed:loading?null:search,icon:const Icon(Icons.search),label:const Text('بحث'))),const SizedBox(width:8),IconButton(onPressed:()=>setState((){q.clear();type.clear();power.clear();speed.clear();search();}),icon:const Icon(Icons.clear),tooltip:'مسح الفلاتر')]),const SizedBox(height:10),
    Expanded(child:loading?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('لا توجد نتائج.')):ListView.builder(itemCount:rows.length,itemBuilder:(c,i)=>Card(child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>MotorDetailsPage(motor:rows[i]))),title:Text('${rows[i]['motor_code']}'),subtitle:Text('${rows[i]['motor_type']} • ${rows[i]['motor_power']} ${rows[i]['motor_power_unit']} • ${rows[i]['motor_speed']} RPM'),trailing:const Icon(Icons.chevron_left))))),
  ]));
  Widget _f(TextEditingController c,String l)=>TextField(controller:c,keyboardType:TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:l,border:const OutlineInputBorder()));
}

class MotorDetailsPage extends StatelessWidget {
  final Map<String,dynamic> motor; const MotorDetailsPage({super.key,required this.motor});
  @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text('${motor['motor_code']}')),body:ListView(padding:const EdgeInsets.all(16),children:[
    ...[['كود المحرك',motor['motor_code']],['نوع المحرك',motor['motor_type']],['القدرة','${motor['motor_power']} ${motor['motor_power_unit']}'],['السرعة','${motor['motor_speed']} RPM'],['خطوة اللف',motor['winding_step']],['قطر السلك',motor['wire_diameter']],['عدد الملفات',motor['coil_count']],['طريقة اللحام',motor['welding_method']],['التوصيل',motor['connection_type']],['القائم بالعمل',motor['technician_name']],['تاريخ الإنشاء',_date(motor['created_at'])],['آخر تحديث',_date(motor['updated_at'])]].map((e)=>Card(child:ListTile(title:Text(e[0].toString()),subtitle:Text(e[1]?.toString()??'—')))),
    const SizedBox(height:8), FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>AddMotorPage(initialMotor:motor))),icon:const Icon(Icons.copy),label:const Text('استخدام البيانات كأساس لموتور جديد')),
  ])));
  static String _date(dynamic v){if(v==null)return '—';try{return DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.parse(v.toString()).toLocal());}catch(_){return '$v';}}
}

class AddMotorPage extends StatefulWidget { final Map<String,dynamic>? initialMotor; const AddMotorPage({super.key,this.initialMotor}); @override State<AddMotorPage> createState()=>_AddMotorPageState(); }
class _AddMotorPageState extends State<AddMotorPage>{ final f=List.generate(9,(_)=>TextEditingController()); bool saving=false; final labels=['نوع المحرك','قدرة المحرك','سرعة المحرك','خطوة اللف','قطر السلك','عدد الملفات','طريقة اللحام','التوصيل','القائم بالعمل على المحرك'];
  @override void initState(){super.initState();final m=widget.initialMotor;if(m!=null){f[0].text='${m['motor_type']??''}';f[1].text='${m['motor_power']??''}';f[2].text='${m['motor_speed']??''}';f[3].text='${m['winding_step']??''}';f[4].text='${m['wire_diameter']??''}';f[5].text='${m['coil_count']??''}';f[6].text='${m['welding_method']??''}';f[7].text='${m['connection_type']??''}';f[8].text='${m['technician_name']??''}';}}
  Future<void> save() async {if(f.any((x)=>x.text.trim().isEmpty)){_msg('من فضلك أكمل جميع البيانات المطلوبة.');return;}final p=double.tryParse(f[1].text.trim()),s=int.tryParse(f[2].text.trim()),w=double.tryParse(f[4].text.trim()),n=int.tryParse(f[5].text.trim());if(p==null||p<=0||s==null||s<=0||w==null||w<=0||n==null||n<=0){_msg('تحقق من القدرة والسرعة وقطر السلك وعدد الملفات.');return;}setState(()=>saving=true);try{final r=await Supabase.instance.client.from('motors').insert({'motor_type':f[0].text.trim(),'motor_power':p,'motor_power_unit':'HP','motor_speed':s,'winding_step':f[3].text.trim(),'wire_diameter':w,'coil_count':n,'welding_method':f[6].text.trim(),'connection_type':f[7].text.trim(),'technician_name':f[8].text.trim()}).select('id,motor_code,created_at,updated_at').single();if(mounted){_msg('تم الحفظ بنجاح — ${r['motor_code']}');if(widget.initialMotor!=null)Navigator.pop(context,r);else for(final x in f)x.clear();}}on PostgrestException catch(e){_msg('فشل الحفظ: ${e.message}');}catch(e){_msg('فشل الحفظ: $e');}finally{if(mounted)setState(()=>saving=false);}}
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[Text(widget.initialMotor==null?'إضافة موتور جديد':'موتور جديد من بيانات سابقة',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:14),...List.generate(9,(i)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:f[i],keyboardType:i==2||i==5?TextInputType.number:i==1||i==4?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,inputFormatters:i==2||i==5?[FilteringTextInputFormatter.digitsOnly]:null,decoration:InputDecoration(labelText:labels[i],border:const OutlineInputBorder(),prefixIcon:const Icon(Icons.edit)))),const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('الكود والتاريخ والوقت يُنشؤون تلقائيًا بواسطة قاعدة البيانات.'))),const SizedBox(height:8),FilledButton.icon(onPressed:saving?null:save,icon:const Icon(Icons.save),label:Text(saving?'جارٍ الحفظ…':'حفظ بيانات المحرك'))]);
}

class AboutPage extends StatelessWidget { const AboutPage({super.key}); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text(appName,style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:12),const Text('تطبيق متخصص لتسجيل وفهرسة بيانات لف المحركات الكهربائية والبحث فيها بسرعة.'),const SizedBox(height:24),Text('الملكية والتطوير',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:8),const Text(ownerName),const Text(ownerPhone),const SizedBox(height:8),const Text(copyrightNotice),const SizedBox(height:4),const Text('© جميع حقوق الملكية الفكرية محفوظة'),const Spacer(),const Text('© عالم بيانات لف المحركات — م. محمد سيد',textAlign:TextAlign.center)])); }
