import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

var listValues = ['1','10','20','50','100','250'];
var globalExchangeRate;

String fromCurrency = 'USD';
String toCurrency = 'AUD';

String fromCurrencyName = 'United States Dollars';
String toCurrencyName = 'Australian Dollars';

String fromCurrencySymbol = '\$';
String toCurrencySymbol = '\$';

var _denoms;
var _lastUpdated = DateTime.now();
var _lastUpdatedString = _lastUpdated.toString();
var formatter = new DateFormat('yyyy-MMM-dd HH:mm');
// Manage the state of our widget. Used to show the snackbar when there is an error. We may not need this once the exchangerate refactor is done
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

_readPreferences() async{

  SharedPreferences prefs = await SharedPreferences.getInstance();

  fromCurrency = prefs.getString('HomeCurrency');
  fromCurrencyName = prefs.getString('HomeCurrencyName');
  fromCurrencySymbol = prefs.getString('HomeCurrencySymbol');

  toCurrency = prefs.getString('AwayCurrency');
  toCurrencySymbol = prefs.getString('AwayCurrencySymbol');
  toCurrencyName = prefs.getString('AwayCurrencyName');

  _denoms = prefs.getStringList('Denominations');
  _lastUpdatedString = prefs.getString(fromCurrency + toCurrency + 'date');

  if (_denoms == null)
  {
    _denoms = listValues;
  }

  if (fromCurrency == null)
    {
      fromCurrency = "AUD";
      fromCurrencyName = 'Australian Dollars';
      fromCurrencySymbol = '\$';
    }

  if (toCurrency == null)
  {
    toCurrency = "USD";
    toCurrencyName = 'US Dollars';
    toCurrencySymbol = '\$';
  }

}

class ExchangeRate{
  var exchangeRate ;

  ExchangeRate(this.exchangeRate);

  Future<double> get getExchangeRate async{
      exchangeRate = await retrieveRate (fromCurrency, toCurrency );
     globalExchangeRate = exchangeRate;

      return exchangeRate;
  }


  readRateFromPrefs(fromCurrency, toCurrency, prefs)
  {
    var fromToCurrency = fromCurrency + toCurrency;
    var exRatePrefs = prefs.getDouble(fromToCurrency) ?? 0.00;
    _lastUpdatedString = prefs.getString(fromToCurrency + 'date');

    return exRatePrefs;
  }

  Future<double> retrieveRate (String fromCurrency, String toCurrency) async
  {

    var exRate ;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (fromCurrency == null){fromCurrency = 'USD';}
    if (toCurrency == null) {toCurrency = 'AUD';}

    Duration difference = DateTime.now().difference(_lastUpdated);
    if (difference.inMinutes < 1 && exRate == 0.00)
    {
      // We got the latest data pretty recently - no need to grab it again
      exRate = readRateFromPrefs(fromCurrency, toCurrency, prefs) ?? 0.00;
      return exRate;
    }

    var fromToCurrency = fromCurrency + "_" + toCurrency;
    var url = 'https://free.currencyconverterapi.com/api/v5/convert?q=' + fromToCurrency;
    var httpClient = new HttpClient();

    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        var jsonString = await response.transform(utf8.decoder).join();

        Map<String, dynamic> decodedMap = json.decode(jsonString);
        exRate = decodedMap['results'][fromToCurrency]['val'];
        _lastUpdated = new DateTime.now();
        _lastUpdatedString = _lastUpdated.toString();

        //Save the keypair exchange rate and last updated date
        prefs.setDouble(fromToCurrency, exRate);
        prefs.setString(fromToCurrency + 'date', _lastUpdated.toString());
      }
    }catch (exception) {

        exRate = prefs.getDouble(fromToCurrency) ?? 0.00;
        _lastUpdatedString = prefs.getString(fromToCurrency + 'date');
        if (exRate == null){exRate = 0.00;}
        if (_lastUpdatedString == null) { _lastUpdated = new DateTime.now(); _lastUpdatedString = _lastUpdated.toString();}
    }

    return exRate;
   }
}

const List _listOfCurrencies = [
{
"currencyID": 'AUD',
"currencyName": 'Australian Dollar',
"currencySymbol": '\$'
},
{
"currencySymbol": '\$',
"currencyName": 'US Dollar',
"currencyID": 'USD'
},
{
  "currencySymbol": '\$',
  "currencyName": 'Canadian Dollar',
  "currencyID": 'CAD'
},

{
  "currencyName": 'Euro Dollar',
  "currencySymbol": '\€',
  "currencyID": 'EUR'
},

{
  "currencyID": 'GBP',
  "currencyName": 'Great British Pound',
  "currencySymbol": '\£'
},

{
  "currencyID": 'NZD',
  "currencyName": 'New Zealand Dollar',
  "currencySymbol": '\$'
},

{
  "currencyID": 'CNY',
  "currencyName": 'Chinese Yuan',
  "currencySymbol": '\¥'
},

{
  "currencyName": 'Japanese Yen',
  "currencySymbol": '\¥',
  "currencyID": 'JPY'
},

{
  "currencyID": 'INR',
  "currencyName": 'Indian Rupee',
  "currencySymbol": '\₹'
},

{
  "currencyID": 'MXN',
  "currencyName": 'Mexican Peso',
  "currencySymbol": '\$'
},

{
  "currencyName": 'Rawandan Franc',
  "currencySymbol": 'F',
  "currencyID": 'RWF'
},

{
  "currencyName": 'Ugandan Shilling',
  "currencySymbol": 'S',
  "currencyID": 'UGX'
}
];


void main() async {
  //await _readPreferences();

  if (_denoms == null) {
    _denoms = listValues;
  }

// Display the app
  debugPaintSizeEnabled = false;

  runApp(new MaterialApp(home: new MyApp(),));
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => new MyAppState();
}

class MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    setState(() {
      // Initial preferences read
      _readPreferences();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await new Future.delayed(new Duration(seconds: 1));
      setState(() {});
    return null;
  }

  void _switchCurrencies(){
    // Flip the currencies around when the button is pressed
    var switchHome = fromCurrency;
    var switchHomeSymbol = fromCurrencySymbol;
    var switchHomeName = fromCurrencyName;

    var switchAway = toCurrency;
    var switchAwaySymbol = toCurrencySymbol;
    var switchAwayName = toCurrencyName;

    fromCurrency = switchAway;
    fromCurrencySymbol = switchAwaySymbol;
    fromCurrencyName = switchAwayName;

    toCurrency = switchHome;
    toCurrencySymbol = switchHomeSymbol;
    toCurrencyName = switchHomeName;

    return ;
  }

  @override
  Widget build(BuildContext context) {
    var ex = new ExchangeRate("0");

    return Scaffold(
      key: _scaffoldKey,
      drawer: new DrawerOnly(),
      appBar: new AppBar(
        backgroundColor: Palette.blueSky,
        title: new Text('Currency Cheatsheet'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.compare_arrows),
              onPressed: () {setState(() {_switchCurrencies();});}
          ),
          new IconButton(icon: new Icon(Icons.refresh),
              onPressed: _handleRefresh,
          ),
        ],
      ),
      body: new RefreshIndicator(onRefresh: _handleRefresh,
            child: _buildScreen(fromCurrency, toCurrency, ex)
      ),
);
  }
}

  Widget _buildScreen(String fromCurrency, String toCurrency, ExchangeRate ex) {
    // Build the screen
    return new Container(

        child:
        FutureBuilder(
          initialData: 1.0000,
          future: ex.getExchangeRate,
          builder: (context, snapshot) {
            return frontPage(snapshot);
          },
        )
    );
  } // Build screen

  Widget frontPage(snapshot) {
    //Here we want to build out our separate widgets
    return new Container(
        padding: new EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // add additional colors to define a multi-point gradient
            colors: [Palette.blueSky,Palette.greenLand,],
          ),
        ),

        child:
        new Column(
            children: <Widget>[
              // Where the magic happens
              Container(child: headerWidget(snapshot),),
              Container(child: Text("") ),
              Expanded(child: denomsList(snapshot),),
              Container(child: Text("Last Updated : " + (formatter.format(DateTime.parse(_lastUpdatedString)) ?? "Never"))),
            ]
        )
    );
  } // MyApp

headerWidget (snapshot) {

  // This is the header card.

  return new Container(
    child:
      new Card(
        elevation: 4.0,
        child: Container(
          padding: EdgeInsets.all(32.0),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Palette.blueSkyLight, Palette.greenLandLight],)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:<Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(child: new Text(fromCurrency  , style:  TextStyle(fontSize: 24.0),textAlign: TextAlign.center),),
                    Expanded(child: new Text(toCurrency , style:  TextStyle(fontSize: 24.0),textAlign: TextAlign.center),),
                  ],
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(child: new Text(fromCurrencyName , style:  TextStyle(fontSize: 12.0),textAlign: TextAlign.center),),
                    Expanded(child: new Text(toCurrencyName , style:  TextStyle(fontSize: 12.0),textAlign: TextAlign.center),),
                  ],
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(child: new Text (fromCurrencySymbol + "  " + "1.0000", style:  TextStyle(fontSize: 24.0),textAlign: TextAlign.center),),
                    Expanded(child: new Text (toCurrencySymbol + "  " + snapshot.data.toStringAsFixed(4), style:  TextStyle(fontSize: 24.0),textAlign: TextAlign.center),),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

Widget denomsList (snapshot) {

  // This is the detail on the main page

  return new Container(
    child:
    new ListView.builder(
        itemCount: _denoms.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            child: Container(
              padding: EdgeInsets.only(left: 32.0,right:32.0),
                color: Palette.greenLandLight,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(_denoms[index].toString(), style:  TextStyle(fontSize: 24.0),textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text(((double.parse(_denoms[index]) * snapshot.data)).toStringAsFixed(4), style:  TextStyle(fontSize: 24.0),textAlign: TextAlign.right),
                    )
                  ],
                )
              )
            );
        }
    ),
  );
}

class Palette {
  // background gradient
  static Color blueSky = Color(0xFF068FFA);
  static Color greenLand = Color(0xFF89ED91);

  // card gradient
  static Color blueSkyLight = Color(0x40068FFA);
  static Color greenLandLight = Color(0x4089ED91);

  static Color blueSkyLighter = Color(0x10068FFA);
}


//This class displays the drawer used on the main pages. This is our settings page
class DrawerOnly extends StatelessWidget{
  @override
  Widget build (BuildContext context) {
    return new Drawer(
      child:
      new Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomCenter,colors: [Palette.blueSky,Palette.greenLand,],),),

        child: new ListView(
      children: <Widget>[
      new Container(height: 100.0,

        child:
        new DrawerHeader(
          padding: EdgeInsets.only(left: 10.0, top: 50.0),
          child: new Text('Settings',style: new TextStyle(fontSize: 23.0),),
          decoration: new BoxDecoration(color: Colors.blue),
        ),
      ),
        new ListTile(
          title: new Text("Local Currency", style: new TextStyle(fontSize: 16.0),),
          leading: const Icon(Icons.airplanemode_active),
          onTap: () {
            // Push currency list
            Navigator.pop(context);
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new HomeCurrencyPage()),);
          },
        ),

        new ListTile(
          title: new Text("Home Currency", style: new TextStyle(fontSize: 16.0),),
          leading: const Icon(Icons.home),
          onTap: () {
            // Push currency list
            Navigator.pop(context);
            Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new AwayCurrencyPage()),
            );
          },
        ),

        new ListTile(
          title: new Text("Currency List", style: new TextStyle(fontSize: 16.0),),
          leading: const Icon(Icons.monetization_on),
          onTap: () {
            // Push currency list
            Navigator.pop(context);
            Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new DenominationsPage()),
            );
          },
        ),

        new ListTile(
          title: new Text("Help", style: new TextStyle(fontSize: 16.0),),
          leading: const Icon(Icons.help),
          onTap: () {
            // Push currency list
            Navigator.pop(context);
            Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new HelpPage()),
            );
          },
        )

        ]
    ),
    )
      );

  }
}

class HomeCurrencyPage extends StatefulWidget {
  // This class displays the list of denominations for selected currency
  // Users can add or remove the denominations they need

  @override
  HomeCurrencyPageWidgetState createState() =>
      HomeCurrencyPageWidgetState();
}

class HomeCurrencyPageWidgetState extends State<HomeCurrencyPage>{

  //class HomeCurrencyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(

        appBar: new AppBar(
          title: new Text("Local Currency"),
        ),
        body:
        new Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomCenter,colors: [Palette.blueSky,Palette.greenLand,],),),
            child:
              new ListView.builder(itemBuilder: (BuildContext context, int index){
              return new CurrencyWidget(
                currencyName: _listOfCurrencies[index]['currencyName'],
                currencyID: _listOfCurrencies[index]['currencyID'],
                currencySymbol: _listOfCurrencies[index]['currencySymbol'],
              );
              },
            itemCount: _listOfCurrencies.length,
            )
        )
    );
  }
}

class AwayCurrencyPage extends StatefulWidget {
  // This class displays the list of denominations for selected currency
  // Users can add or remove the denominations they need

  @override
  AwayCurrencyPageWidgetState createState() =>
      AwayCurrencyPageWidgetState();
}

class AwayCurrencyPageWidgetState extends State<AwayCurrencyPage>{

  @override
  Widget build(BuildContext context) {
    return new Scaffold(

        appBar: new AppBar(
          title: new Text("Home Currency"),
        ),
        body:
        new Container(
          decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomCenter,colors: [Palette.blueSky,Palette.greenLand,],),),
        child:
        new ListView.builder(itemBuilder: (BuildContext context, int index){
          return new AwayCurrencyWidget(
            currencyID: _listOfCurrencies[index]['currencyID'],
            currencyName: _listOfCurrencies[index]['currencyName'],
            currencySymbol: _listOfCurrencies[index]['currencySymbol'],
          );
        },
          itemCount: _listOfCurrencies.length,
        )
        ),
    );
  }
}


class HelpPage extends StatefulWidget {
  // This class displays the list of denominations for selected currency
  // Users can add or remove the denominations they need

  @override
  HelpPageWidgetState createState() =>
      HelpPageWidgetState();
}

class HelpPageWidgetState extends State<HelpPage> {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Help"),
      ),
      body:
      new Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // add additional colors to define a multi-point gradient
            colors: [Palette.blueSky,Palette.greenLand,],
          ),
        ),

        padding: new EdgeInsets.all(16.0),
        child:
        new Column(
          children: <Widget>[
            Card(
              elevation: 4.0,
              child: Container(
                padding: EdgeInsets.all(32.0),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Palette.blueSkyLight, Palette.greenLandLight],)),
                child:
                  new RichText(text: TextSpan(style: new TextStyle(fontSize: 16.0, color:Colors.black),
                    children: <TextSpan>[
                      TextSpan(text: 'Currency Cheatsheet\n\n', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                      TextSpan(text: 'A simple currency converter designed to show common denominations at a glance.'),
                      TextSpan(text: '\n\n', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Usage\n\n', style: TextStyle(fontSize: 21.0, fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Select the currency where you are currently located. \n\nNext, choose the currency of the country you are from.\n\n'),
                      TextSpan(text: 'Modify the currency list to show your common conversions. You might like to pick the cost of a coffee or a burger\n\n'),
                      TextSpan(text: 'Refresh to get the latest conversion rate'),
                    ],
                    ),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DenominationsPage extends StatefulWidget {
  // This class displays the list of denominations for selected currency
  // Users can add or remove the denominations they need

  @override
  _DenominationsPageWidgetState createState() =>
      _DenominationsPageWidgetState();
}

class _DenominationsPageWidgetState extends State<DenominationsPage>{

  var items = _denoms;

  // Save the list of denominations to the preferences file
  _saveList() async{

    List<int> intList = new List();

    //Extract string list and parse to int list
    for (var i=0; i < items.length; i++)
    {
      intList.add(int.parse(items[i]));
    }

    //Sort the new list
    intList.sort();

    //Build the array ready to repopulate
    List<String> strList = new List();

    // Pop it back into string format so we can save it
    for (var q=0; q < intList.length; q++){
      strList.add(intList[q].toString());
    }

    //Set items to the newly built strList
    items = strList;

    //Save it to disk
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('Denominations', items);
    await _readPreferences();

  }

  final TextEditingController eCtrl = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      //drawer: new DrawerOnly(),
        appBar: new AppBar(
          title: new Text("Currency List"),
        ),

        body:
        new Container(
            padding: EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomCenter,colors: [Palette.blueSky,Palette.greenLand,],),),
            child: new Column(
              children: <Widget>[
                Card(
                  elevation: 4.0,
                  child : new Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Palette.blueSkyLight, Palette.greenLandLight],)),
                    child :
                    new TextField(
                      controller: eCtrl,
                      decoration: InputDecoration(labelText: 'Add new value, swipe existing to remove'),
                      keyboardType: TextInputType.number,
                      onSubmitted: (text) {
                        items.add(text);
                        eCtrl.clear();
                        setState(() {_saveList();});
                    },
                  ),
                ),
                ),

                new Text(""),
                new Text(""),

                new Expanded(child:
                // new RefreshIndicator(child:

                new ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index)
                  {
                    final item = items[index];

                    return Dismissible(
                      key: Key(item),
                      onDismissed: (direction) {
                      setState(() {
                          items.removeAt(index);
                          _saveList();
                      });
                      Scaffold.of(context).showSnackBar(SnackBar(content: Text("$item removed")));
                  },
                  background: Container(color: Colors.red,alignment: FractionalOffset.centerRight,child: new IconButton(icon: Icon(Icons.delete),color: Colors.black,)),
                      child: Card(

                        elevation: 4.0,
                      child : new Container(
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [Palette.blueSkyLight, Palette.greenLandLight],)),
                          child: ListTile(title: new Text('$item',textAlign: TextAlign.right, style: new TextStyle(fontSize: 20.0 ),)
                        ),
                      )
                      )
                );
              },
            ),
            )
          ],
        )
        ),
    );
  }

}

class AwayCurrencyWidget extends StatefulWidget {

  final String currencyName;
  final String currencySymbol;
  final String currencyID;

  AwayCurrencyWidget({Key key, this.currencyName, this.currencySymbol, this.currencyID}) : super (key: key);

  @override
  AwayCurrencyWidgetState createState() =>
      AwayCurrencyWidgetState();
}

class AwayCurrencyWidgetState extends State<AwayCurrencyWidget>{

  var _isSelected = false;

  tappedItem(String currencyID, String currencySymbol, String currencyName) async{
    _isSelected = true;

    //Set the exchange rate to 0 so we dont get a false read
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('AwayCurrency', currencyID);
    await prefs.setString('AwayCurrencyName', currencyName);
    await prefs.setString('AwayCurrencySymbol', currencySymbol);

    toCurrency = currencyID;
    toCurrencySymbol = currencySymbol;
    toCurrencyName = currencyName;

  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        new Container(
          padding: EdgeInsets.only(left: 32.0, right: 32.0, top: 10.0),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Palette.blueSkyLight, Palette.greenLandLight],)),
            margin: new EdgeInsets.symmetric(vertical: 1.0),
            child: new Card(
            elevation: 4.0,

            child : new Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Palette.blueSkyLight, Palette.greenLandLight],)),
            child: new ListTile(
                leading: new Text(widget.currencyID),
                title: new Text(widget.currencyName),
                subtitle: new Text(widget.currencySymbol),
                trailing: new Icon (_isSelected ? Icons.check : null),

                onTap: () {
                  setState(() {
                    tappedItem(widget.currencyID, widget.currencySymbol, widget.currencyName);
                    Navigator.pop(context);
                  });
                }
            )
        ),
        ),
        ),
      ],
    );
  }
}

class CurrencyWidget extends StatefulWidget {

  final String currencyName;
  final String currencySymbol;
  final String currencyID;

  CurrencyWidget({Key key, this.currencyName, this.currencySymbol, this.currencyID}) : super (key: key);

  @override
  CurrencyWidgetState createState() =>
      CurrencyWidgetState();
}

class CurrencyWidgetState extends State<CurrencyWidget> {

  var _isSelected = false;

  tappedItem(String currencyID, String currencyName,
      String currencySymbol) async {
    _isSelected = true;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('HomeCurrency', currencyID);
    await prefs.setString('HomeCurrencyName', currencyName);
    await prefs.setString('HomeCurrencySymbol', currencySymbol);
    fromCurrency = currencyID;
    fromCurrencySymbol = currencySymbol;
    fromCurrencyName = currencyName;
  }

  @override
  Widget build(BuildContext context) {

      return new Column(
        children: [
          Container(
              padding: EdgeInsets.only(left: 32.0, right: 32.0, top: 10.0),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Palette.blueSkyLight, Palette.greenLandLight],)),
              margin: new EdgeInsets.symmetric(vertical: 1.0),
              child: new Card(
                elevation: 4.0,
                child : new Container(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [Palette.blueSkyLight, Palette.greenLandLight],)),
                    child: new ListTile(

                        leading: new Text(widget.currencyID),
                        title: new Text(widget.currencyName),
                        subtitle: new Text(widget.currencySymbol),
                        trailing: new Icon (_isSelected ? Icons.check : null),

                        onTap: () {
                          setState(() {
                            tappedItem(widget.currencyID, widget.currencyName,widget.currencySymbol);
                            Navigator.pop(context);
                          });
                        }
                    )
                )

          ),
          ),
        ],
      );
  }
}