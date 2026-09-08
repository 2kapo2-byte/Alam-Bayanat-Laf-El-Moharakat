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
    await Supabase.initialize(url: url, anonKey: key);
  }
  runApp(const MotorApp());
}

class MotorApp extends StatelessWidget {
  const MotorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: appName,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, fontFamily: 'sans'),
        locale: const Locale('ar'),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage> {
  int index=0;
  @override Widget build(BuildContext context) {
    final pages=[const Dashboard(), const MotorsPage(), const AddMotorPage(), const AboutPage()];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text(appName, style: TextStyle(fontWeight: FontWeight.bold))),
      body: pages[index],
      bottomNavigationBar: NavigationBar(selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),destinations:const[
        NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'الرئيسية'),
        NavigationDestination(icon:Icon(Icons.search),label:'السجل'),
        NavigationDestination(icon:Icon(Icons.add_circle_outline),selectedIcon:Icon(Icons.add_circle),label:'إضافة'),
        NavigationDestination(icon:Icon(Icons.info_outline),label:'حول التطبيق'),
      ]),
    ));
  }
}

class Dashboard extends StatelessWidget { const Dashboard({super.key}); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  Text('قاعدة بيانات لف المحركات',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)), const SizedBox(height:8),
  Text('سجّل بيانات المحركات واسترجعها بسرعة عند الحاجة.'), const SizedBox(height:20),
  Row(children:[Expanded(child:_StatCard(title:'إجمالي المحركات',value:'—',icon:Icons.electric_bolt)),SizedBox(width:10),Expanded(child:_StatCard(title:'مسجل اليوم',value:'—',icon:Icons.today))]), const SizedBox(height:16),
  Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('ابدأ الآن',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),SizedBox(height:8),Text('أضف أول سجل أو ابحث في السجل السابق حسب النوع والقدرة والسرعة.')]))),
])); }
class _StatCard extends StatelessWidget { final String title,value; final IconData icon; const _StatCard({required this.title,required this.value,required this.icon}); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[Icon(icon,size:30),const SizedBox(height:6),Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text(title,textAlign:TextAlign.center)]))); }

class MotorsPage extends StatefulWidget { const MotorsPage({super.key}); @override State<MotorsPage> createState()=>_MotorsPageState(); }
class _MotorsPageState extends State<MotorsPage>{ final type=TextEditingController(),power=TextEditingController(),speed=TextEditingController(); bool loading=false; List<Map<String,dynamic>> rows=[];
 Future<void> search() async { setState(()=>loading=true); try { if(!Supabase.instance.isInitialized){setState(()=>rows=[]);return;} var q=Supabase.instance.client.from('motors').select().order('created_at',ascending:false); if(type.text.trim().isNotEmpty) q=q.ilike('motor_type','%${type.text.trim()}%'); if(power.text.trim().isNotEmpty) q=q.ilike('motor_power','%${power.text.trim()}%'); if(speed.text.trim().isNotEmpty) q=q.ilike('motor_speed','%${speed.text.trim()}%'); rows=List<Map<String,dynamic>>.from(await q); } catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تحميل السجل: $e'))); } finally {if(mounted)setState(()=>loading=false);} }
 @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(16),child:Column(children:[Row(children:[Expanded(child:_field(type,'نوع المحرك')),const SizedBox(width:8),Expanded(child:_field(power,'القدرة')),const SizedBox(width:8),Expanded(child:_field(speed,'السرعة'))]),const SizedBox(height:10),FilledButton.icon(onPressed:loading?null:search,icon:const Icon(Icons.search),label:const Text('بحث')),const SizedBox(height:10),Expanded(child:loading?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('لا توجد نتائج. نفّذ بحثًا أو أضف أول سجل.')):ListView.builder(itemCount:rows.length,itemBuilder:(c,i)=>Card(child:ListTile(title:Text(rows[i]['motor_code']??'بدون كود'),subtitle:Text('${rows[i]['motor_type']??''} • ${rows[i]['motor_power']??''} • ${rows[i]['motor_speed']??''}'),trailing:Text(_date(rows[i]['created_at']))))))])); }
 Widget _field(TextEditingController x,String h)=>TextField(controller:x,decoration:InputDecoration(labelText:h,border:const OutlineInputBorder()),textInputAction:TextInputAction.search);
 String _date(dynamic v){if(v==null)return '';try{return DateFormat('yyyy/MM/dd HH:mm').format(DateTime.parse(v.toString()).toLocal());}catch(_){return v.toString();}}
}

class AddMotorPage extends StatefulWidget { const AddMotorPage({super.key}); @override State<AddMotorPage> createState()=>_AddMotorPageState(); }
class _AddMotorPageState extends State<AddMotorPage>{ final f=List.generate(9,(_)=>TextEditingController()); bool saving=false; final labels=['نوع المحرك','قدرة المحرك','سرعة المحرك','خطوة اللف','قطر السلك','عدد الملفات','طريقة اللحام','التوصيل','القائم بالعمل على المحرك'];
 Future<void> save() async { if(f.take(9).any((x)=>x.text.trim().isEmpty)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('من فضلك أكمل جميع البيانات المطلوبة.')));return;} if(!Supabase.instance.isInitialized){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('قاعدة البيانات غير مهيأة. أضف SUPABASE_URL و SUPABASE_ANON_KEY عند البناء.')));return;} setState(()=>saving=true); try { final data={'motor_type':f[0].text.trim(),'motor_power':f[1].text.trim(),'motor_speed':f[2].text.trim(),'winding_step':f[3].text.trim(),'wire_diameter':f[4].text.trim(),'coil_count':int.tryParse(f[5].text.trim()),'welding_method':f[6].text.trim(),'connection_type':f[7].text.trim(),'technician_name':f[8].text.trim()}; final r=await Supabase.instance.client.from('motors').insert(data).select('motor_code,created_at').single(); if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم الحفظ بنجاح — ${r['motor_code']}'))); for(final x in f)x.clear();}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل الحفظ: $e')));}finally{if(mounted)setState(()=>saving=false);}}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[...List.generate(9,(i)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:f[i],keyboardType:i==5?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:labels[i],border:const OutlineInputBorder(),prefixIcon:const Icon(Icons.edit)))),const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('التاريخ والوقت يُسجلان تلقائيًا بواسطة قاعدة البيانات ولا يحتاجان إدخالًا يدويًا.'))),const SizedBox(height:8),FilledButton.icon(onPressed:saving?null:save,icon:const Icon(Icons.save),label:Text(saving?'جارٍ الحفظ…':'حفظ بيانات المحرك'))]; }
}

class AboutPage extends StatelessWidget { const AboutPage({super.key}); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(appName,style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:12),const Text('تطبيق متخصص لتسجيل وفهرسة بيانات لف المحركات الكهربائية والبحث فيها بسرعة.'),const SizedBox(height:24),Text('الملكية والتطوير',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:8),const Text(ownerName),const Text(ownerPhone),const SizedBox(height:8),const Text(copyrightNotice),const SizedBox(height:4),const Text('© جميع حقوق الملكية الفكرية محفوظة'),const Spacer(),const Text('© عالم بيانات لف المحركات — م. محمد سيد',textAlign:TextAlign.center)])); }
