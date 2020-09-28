import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pwn_check/src/models/account_model.dart';
import 'package:pwn_check/src/models/breach_model.dart';
import 'package:pwn_check/src/models/paste_model.dart';
import 'package:sqflite/sqflite.dart';

class Db {
  Database _db;
  static const DB_NAME = 'pwn.db';

  static Future<Db> create() async {
    Db dbInstance = Db._();
    await dbInstance.init();
    return dbInstance;
  }

  Db._();

  Future<void> init() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), DB_NAME),
      onCreate: (newDb, version) async {
        print("Creating database");
        for (String stmt in _CREATE_TABLE_STATEMENTS) {
          await newDb.execute(stmt);
          print(stmt);
        }
        print("Tables Created");
      },
      version: 1,
    );
  }

  Future<List<AccountModel>> fetchAccounts() async {
//     final tb = await _db.rawQuery('''SELECT
//     name
// FROM
//     sqlite_master
// WHERE
//     type ='table' AND
//     name NOT LIKE 'sqlite_%';''');
//     print(tb);

    final results = await _db.rawQuery(
        '''SELECT account, sum(bc) as breachCount, sum(pc) as pasteCount, breachesChecked, pastesChecked
    from (
      select account, CASE WHEN accountSeq IS NULL THEN 0 ELSE count(*) END as bc, 0 as pc, breachesChecked, pastesChecked from accounts left join account_breach on accounts_seq = accountSeq GROUP BY account
        UNION ALL
      select account, 0 as bc, CASE WHEN accountSeq IS NULL THEN 0 ELSE count(*) END as pc, breachesChecked, pastesChecked from accounts left join account_paste on accounts_seq = accountSeq GROUP BY account) tb
    GROUP BY account;''');
    print("Fetching accounts.. ${results.length} found");
    if (results.length > 0) {
      return results
          .map<AccountModel>((res) => AccountModel.fromJson(res))
          .toList();
    }
    return <AccountModel>[];
  }

  Future<int> insertAccount(
    AccountModel account, {
    bool returnSeqIfExists = false,
  }) async {
    print("Inserting account: $account");
    int result = await _db.insert(
      'accounts',
      account.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    print(result);
    if (result == null && returnSeqIfExists) {
      final mapList = await _db.query(
        "accounts",
        columns: ['accounts_seq'],
        where: "account = ?",
        whereArgs: [account.account],
      );
      if (mapList.length > 0) {
        result = mapList.first["accounts_seq"];
        print("account inserted: $account");
      }
    } else {
      print("account already in db: $account");
    }
    return result;
  }

  Future<void> deleteAccount(String account) async {
    final results = await _db.query(
      "accounts",
      columns: ["accounts_seq"],
      where: "account = ?",
      whereArgs: [account],
    );
    if (results.length == 0) return;

    int accounts_seq = results.first["accounts_seq"];
    final batch = _db.batch();
    batch.delete(
      "accounts",
      where: "account = ?",
      whereArgs: [account],
    );
    batch.delete(
      "account_breach",
      where: "accountSeq = ?",
      whereArgs: [accounts_seq],
    );
    batch.delete(
      "account_paste",
      where: "accountSeq = ?",
      whereArgs: [accounts_seq],
    );
    await batch.commit(noResult: true);
  }

  // TODO: Add logic for updating breaches with new information
  Future<void> insertBreaches(List<BreachModel> breaches,
      [AccountModel account]) async {
    print("Running insertBreaches method");
    Map<String, int> breachMap = Map<String, int>();
    final bool noResult = account == null;

    if (account != null) {
      // First get all breaches that already exist in DB
      final breachNames = breaches.map<String>((b) => b.name).toList();
      final qs = List.filled(breachNames.length, "?").join(", ");
      final existingBreaches = await _db.query(
        "breaches",
        columns: ["breaches_seq", "name"],
        where: "name IN ($qs)",
        whereArgs: breachNames,
      );
      // Create a map that stores breach name => sequence
      for (var breach in existingBreaches) {
        breachMap[breach["name"]] = breach["breaches_seq"];
      }
      print("breach map: $breachMap");
    }

    // Insert/update the breaches
    final batch = _db.batch();
    // Insert new breaches, collect sequences if account is not null
    print("Inserting ${breaches.length} breaches");
    for (BreachModel breach in breaches) {
      if (!breachMap.containsKey(breach.name)) {
        print("Inserting breach named: ${breach.name}");
        batch.insert(
          "breaches",
          breach.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    try {
      final results = await batch.commit(noResult: noResult);
      print("Batch commit results: $results");
      // Add the account_breach entries
      if (results.length + breachMap.length > 0 && !noResult) {
        final accountSeq = await insertAccount(
          account,
          returnSeqIfExists: true,
        );
        // Add the newly entered breach links
        for (int seq in results) {
          print("Inserting accountSeq: $accountSeq, breachSeq: $seq");
          batch.insert(
            "account_breach",
            {
              "accountSeq": accountSeq,
              "breachSeq": seq,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        // Add the links to account for existing breaches
        // Now update breaches already in DB
        if (breachMap.length > 0) {
          for (BreachModel breach in breaches) {
            if (breachMap.containsKey(breach.name)) {
              print("Updating breach named: ${breach.name}");
              batch.update(
                "breaches",
                breach.toDbMap(),
                where: "breaches_seq = ?",
                whereArgs: [breachMap[breach.name]],
              );
              print(
                  "Inserting accountSeq: $accountSeq, breachSeq: ${breachMap[breach.name]}");
              batch.insert(
                "account_breach",
                {
                  "accountSeq": accountSeq,
                  "breachSeq": breachMap[breach.name],
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }
        batch.commit();
      }
    } catch (err) {
      print(err);
    }
  }

  Future<void> insertPastes(List<PasteModel> pastes,
      [AccountModel account]) async {
    print("Running insertPastes method");
    Map<String, int> pasteMap = Map<String, int>();
    final bool noResult = account == null;

    if (account != null) {
      // First get all pastes that already exist in DB
      final pasteIds = pastes.map<String>((b) => b.id).toList();
      final qs = List.filled(pasteIds.length, "?").join(", ");
      final existingPastes = await _db.query(
        "pastes",
        columns: ["pastes_seq", "id"],
        where: "id IN ($qs)",
        whereArgs: pasteIds,
      );
      // Create a map that stores paste id => sequence
      for (var paste in existingPastes) {
        pasteMap[paste["id"]] = paste["pastes_seq"];
      }
      print("paste map: $pasteMap");
    }

    // Insert/update the pastes
    final batch = _db.batch();
    // Insert new pastes, collect sequences if account is not null
    print("Inserting ${pastes.length} pastes");
    for (PasteModel paste in pastes) {
      if (!pasteMap.containsKey(paste.id)) {
        print("Inserting paste named: ${paste.id}");
        batch.insert(
          "pastes",
          paste.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    try {
      final results = await batch.commit(noResult: noResult);
      print("Batch commit results: $results");
      // Add the account_breach entries
      if (results.length + pasteMap.length > 0 && !noResult) {
        final accountSeq = await insertAccount(
          account,
          returnSeqIfExists: true,
        );
        // Add the newly entered paste links
        for (int seq in results) {
          print("Inserting accountSeq: $accountSeq, pasteSeq: $seq");
          batch.insert(
            "account_paste",
            {
              "accountSeq": accountSeq,
              "pasteSeq": seq,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        // Add the links to account for existing pastes
        // Now update pastes already in DB
        if (pasteMap.length > 0) {
          for (PasteModel paste in pastes) {
            if (pasteMap.containsKey(paste.id)) {
              print("Updating paste named: ${paste.id}");
              batch.update(
                "pastes",
                paste.toDbMap(),
                where: "pastes_seq = ?",
                whereArgs: [pasteMap[paste.id]],
              );
              print(
                  "Inserting accountSeq: $accountSeq, pasteSeq: ${pasteMap[paste.id]}");
              batch.insert(
                "account_paste",
                {
                  "accountSeq": accountSeq,
                  "pasteSeq": pasteMap[paste.id],
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }
        batch.commit();
      }
    } catch (err) {
      print(err);
    }
  }

  Future<List<BreachModel>> fetchBreaches([String account]) async {
    String sql =
        '''SELECT * FROM accounts LEFT JOIN account_breach ON accountSeq = accounts_seq
    LEFT JOIN breaches ON breachSeq = breaches_seq
    ''';
    if (account != null) {
      sql += " WHERE account = ?";
    }
    sql += " ORDER BY breachDate DESC";
    final results = await _db.rawQuery(sql, [account]);
    final breaches =
        results.map<BreachModel>((item) => BreachModel.fromDb(item)).toList();
    return breaches;
  }

  void deleteData() async {
    await _db.delete("accounts");
    await _db.delete("breaches");
    await _db.delete("pastes");
    await _db.delete("account_paste");
    await _db.delete("account_breach");
  }

  void dump() async {
    var results = await _db.query('accounts');
    print("Accounts table:");
    for (var r in results) {
      print(r);
    }
    results = await _db.query('breaches');
    print("Breaches table:");
    for (var r in results) {
      print('${r["breaches_seq"]}, ${r["name"]}, ${r["title"]}');
    }
    results = await _db.query('pastes');
    print("Pastes table:");
    for (var r in results) {
      print('${r["pastes_seq"]}, ${r["id"]}, ${r["title"]}');
    }
    results = await _db.query('account_breach');
    print("account_breach table:");
    for (var r in results) {
      print(r);
    }
    results = await _db.query('account_paste');
    print("account_paste table:");
    for (var r in results) {
      print(r);
    }
  }

  void deleteDb() {
    deleteDatabase(DB_NAME);
  }

  void test() {
    _db.execute(
        "INSERT INTO account_breach (accountSeq, breachSeq) VALUES (2, 20)");
    _db.execute(
        "INSERT INTO account_breach (accountSeq, breachSeq) VALUES (22, 0)");
  }

  static const _CREATE_TABLE_STATEMENTS = [
    // '''
    // CREATE TABLE accounts
    // (
    //   accounts_seq INTEGER PRIMARY KEY,
    //   account TEXT UNIQUE NOT NULL
    // );
    // ''',
    '''
    CREATE TABLE accounts
    (
      accounts_seq INTEGER PRIMARY KEY,
      account TEXT UNIQUE NOT NULL,
      pastesChecked INTEGER,
      breachesChecked INTEGER
    );
    ''',
    '''
    CREATE TABLE pastes
    (
      pastes_seq INTEGER PRIMARY KEY,
      source TEXT NOT NULL DEFAULT "",
      id TEXT UNIQUE NOT NULL,
      title TEXT NOT NULL DEFAULT "",
      date INTEGER,
      emailCount INTEGER NOT NULL DEFAULT 0
    );
    ''',
    '''
    CREATE TABLE breaches
    (
      breaches_seq INTEGER PRIMARY KEY,
      name TEXT UNIQUE NOT NULL,
      title TEXT NOT NULL DEFAULT "",
      domain TEXT NOT NULL DEFAULT "",
      breachDate INTEGER,
      addedDate INTEGER,
      modifiedDate INTEGER,
      pwnCount INTEGER NOT NULL DEFAULT 0,
      description TEXT NOT NULL DEFAULT "",
      dataClasses BLOB,
      isVerified INTEGER NOT NULL DEFAULT 0,
      isFabricated INTEGER NOT NULL DEFAULT 0,
      isSensitive INTEGER NOT NULL DEFAULT 0,
      isRetired INTEGER NOT NULL DEFAULT 0,
      isSpamList INTEGER NOT NULL DEFAULT 0,
      logoPath TEXT NOT NULL DEFAULT ""
    );
    ''',
    '''
    CREATE TABLE account_paste
    (
      accountSeq INTEGER NOT NULL,
      pasteSeq INTEGER NOT NULL,
      FOREIGN KEY (accountSeq) REFERENCES accounts(seq),
      FOREIGN KEY (pasteSeq) REFERENCES pastes(seq)
    );
    ''',
    '''
    CREATE TABLE account_breach
    (
      accountSeq INTEGER NOT NULL,
      breachSeq INTEGER NOT NULL,
      FOREIGN KEY (accountSeq) REFERENCES accounts (seq),
      FOREIGN KEY (breachSeq) REFERENCES breaches (seq),
      UNIQUE(accountSeq, breachSeq)
    );
    '''
  ];
}

final BREACH_EX = <BreachModel>[
  BreachModel.fromJson({
    "Name": "AntiPublic",
    "Title": "Anti Public Combo List",
    "Domain": "",
    "BreachDate": "2016-12-16",
    "AddedDate": "2017-05-04T22:07:38Z",
    "ModifiedDate": "2017-05-04T22:07:38Z",
    "PwnCount": 457962538,
    "Description":
        "In December 2016, a huge list of email address and password pairs appeared in a &quot;combo list&quot; referred to as &quot;Anti Public&quot;. The list contained 458 million unique email addresses, many with multiple different passwords hacked from various online systems. The list was broadly circulated and used for &quot;credential stuffing&quot;, that is attackers employ it in an attempt to identify other online systems where the account owner had reused their password. For detailed background on this incident, read <a href=\"https://www.troyhunt.com/password-reuse-credential-stuffing-and-another-1-billion-records-in-have-i-been-pwned\" target=\"_blank\" rel=\"noopener\">Password reuse, credential stuffing and another billion records in Have I Been Pwned</a>.",
    "LogoPath": "https://haveibeenpwned.com/Content/Images/PwnedLogos/List.png",
    "DataClasses": ["Email addresses", "Passwords"],
    "IsVerified": false,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  }),
  BreachModel.fromJson({
    "Name": "Chegg",
    "Title": "Chegg",
    "Domain": "chegg.com",
    "BreachDate": "2018-04-28",
    "AddedDate": "2019-08-16T07:24:58Z",
    "ModifiedDate": "2019-08-16T07:24:58Z",
    "PwnCount": 39721127,
    "Description":
        "In April 2018, the textbook rental service <a href=\"https://techcrunch.com/2018/09/26/chegg-resets-40-million-user-passwords-after-data-breach/\" target=\"_blank\" rel=\"noopener\">Chegg suffered a data breach</a> that impacted 40 million subscribers. The exposed data included email addresses, usernames, names and passwords stored as unsalted MD5 hashes. The data was provided to HIBP by a source who requested it be attributed to \"JimScott.Sec@protonmail.com\".",
    "LogoPath":
        "https://haveibeenpwned.com/Content/Images/PwnedLogos/Chegg.png",
    "DataClasses": ["Email addresses", "Names", "Passwords", "Usernames"],
    "IsVerified": true,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  }),
  BreachModel.fromJson({
    "Name": "Collection1",
    "Title": "Collection #1",
    "Domain": "",
    "BreachDate": "2019-01-07",
    "AddedDate": "2019-01-16T21:46:07Z",
    "ModifiedDate": "2019-01-16T21:50:21Z",
    "PwnCount": 772904991,
    "Description":
        "In January 2019, a large collection of credential stuffing lists (combinations of email addresses and passwords used to hijack accounts on other services) was discovered being distributed on a popular hacking forum. The data contained almost 2.7 <em>billion</em> records including 773 million unique email addresses alongside passwords those addresses had used on other breached services. Full details on the incident and how to search the breached passwords are provided in the blog post <a href=\"https://www.troyhunt.com/the-773-million-record-collection-1-data-reach\" target=\"_blank\" rel=\"noopener\">The 773 Million Record \"Collection #1\" Data Breach</a>.",
    "LogoPath": "https://haveibeenpwned.com/Content/Images/PwnedLogos/List.png",
    "DataClasses": ["Email addresses", "Passwords"],
    "IsVerified": false,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  }),
  BreachModel.fromJson({
    "Name": "PDL",
    "Title": "Data Enrichment Exposure From PDL Customer",
    "Domain": "",
    "BreachDate": "2019-10-16",
    "AddedDate": "2019-11-22T20:13:04Z",
    "ModifiedDate": "2019-11-22T20:13:04Z",
    "PwnCount": 622161052,
    "Description":
        "In October 2019, <a href=\"https://www.troyhunt.com/data-enrichment-people-data-labs-and-another-622m-email-addresses\" target=\"_blank\" rel=\"noopener\">security researchers Vinny Troia and Bob Diachenko identified an unprotected Elasticsearch server holding 1.2 billion records of personal data</a>. The exposed data included an index indicating it was sourced from data enrichment company People Data Labs (PDL) and contained 622 million unique email addresses. The server was not owned by PDL and it's believed a customer failed to properly secure the database. Exposed information included email addresses, phone numbers, social media profiles and job history data.",
    "LogoPath": "https://haveibeenpwned.com/Content/Images/PwnedLogos/List.png",
    "DataClasses": [
      "Email addresses",
      "Employers",
      "Geographic locations",
      "Job titles",
      "Names",
      "Phone numbers",
      "Social media profiles"
    ],
    "IsVerified": true,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  }),
  BreachModel.fromJson({
    "Name": "ExploitIn",
    "Title": "Exploit.In",
    "Domain": "",
    "BreachDate": "2016-10-13",
    "AddedDate": "2017-05-06T07:03:18Z",
    "ModifiedDate": "2017-05-06T07:03:18Z",
    "PwnCount": 593427119,
    "Description":
        "In late 2016, a huge list of email address and password pairs appeared in a &quot;combo list&quot; referred to as &quot;Exploit.In&quot;. The list contained 593 million unique email addresses, many with multiple different passwords hacked from various online systems. The list was broadly circulated and used for &quot;credential stuffing&quot;, that is attackers employ it in an attempt to identify other online systems where the account owner had reused their password. For detailed background on this incident, read <a href=\"https://www.troyhunt.com/password-reuse-credential-stuffing-and-another-1-billion-records-in-have-i-been-pwned\" target=\"_blank\" rel=\"noopener\">Password reuse, credential stuffing and another billion records in Have I Been Pwned</a>.",
    "LogoPath": "https://haveibeenpwned.com/Content/Images/PwnedLogos/List.png",
    "DataClasses": ["Email addresses", "Passwords"],
    "IsVerified": false,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  }),
  BreachModel.fromJson({
    "Name": "Lastfm",
    "Title": "Last.fm",
    "Domain": "last.fm",
    "BreachDate": "2012-03-22",
    "AddedDate": "2016-09-20T20:00:49Z",
    "ModifiedDate": "2016-09-20T20:00:49Z",
    "PwnCount": 37217682,
    "Description":
        "In March 2012, the music website <a href=\"https://techcrunch.com/2016/09/01/43-million-passwords-hacked-in-last-fm-breach/\" target=\"_blank\" rel=\"noopener\">Last.fm was hacked</a> and 43 million user accounts were exposed. Whilst <a href=\"http://www.last.fm/passwordsecurity\" target=\"_blank\" rel=\"noopener\">Last.fm knew of an incident back in 2012</a>, the scale of the hack was not known until the data was released publicly in September 2016. The breach included 37 million unique email addresses, usernames and passwords stored as unsalted MD5 hashes.",
    "LogoPath":
        "https://haveibeenpwned.com/Content/Images/PwnedLogos/Lastfm.png",
    "DataClasses": [
      "Email addresses",
      "Passwords",
      "Usernames",
      "Website activity"
    ],
    "IsVerified": true,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  }),
  BreachModel.fromJson({
    "Name": "MySpace",
    "Title": "MySpace",
    "Domain": "myspace.com",
    "BreachDate": "2008-07-01",
    "AddedDate": "2016-05-31T00:12:29Z",
    "ModifiedDate": "2016-05-31T00:12:29Z",
    "PwnCount": 359420698,
    "Description":
        "In approximately 2008, <a href=\"http://motherboard.vice.com/read/427-million-myspace-passwords-emails-data-breach\" target=\"_blank\" rel=\"noopener\">MySpace suffered a data breach that exposed almost 360 million accounts</a>. In May 2016 the data was offered up for sale on the &quot;Real Deal&quot; dark market website and included email addresses, usernames and SHA1 hashes of the first 10 characters of the password converted to lowercase and stored without a salt. The exact breach date is unknown, but <a href=\"https://www.troyhunt.com/dating-the-ginormous-myspace-breach\" target=\"_blank\" rel=\"noopener\">analysis of the data suggests it was 8 years before being made public</a>.",
    "LogoPath":
        "https://haveibeenpwned.com/Content/Images/PwnedLogos/MySpace.png",
    "DataClasses": ["Email addresses", "Passwords", "Usernames"],
    "IsVerified": true,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  }),
  BreachModel.fromJson({
    "Name": "Pemiblanc",
    "Title": "Pemiblanc",
    "Domain": "pemiblanc.com",
    "BreachDate": "2018-04-02",
    "AddedDate": "2018-07-09T22:16:26Z",
    "ModifiedDate": "2018-07-09T22:16:26Z",
    "PwnCount": 110964206,
    "Description":
        "In April 2018, a credential stuffing list containing 111 million email addresses and passwords known as <a href=\"https://www.troyhunt.com/the-111-million-pemiblanc-credential-stuffing-list\" target=\"_blank\" rel=\"noopener\">Pemiblanc</a> was discovered on a French server. The list contained email addresses and passwords collated from different data breaches and used to mount account takeover attacks against other services. <a href=\"https://www.troyhunt.com/the-111-million-pemiblanc-credential-stuffing-list\" target=\"_blank\" rel=\"noopener\">Read more about the incident.</a>",
    "LogoPath": "https://haveibeenpwned.com/Content/Images/PwnedLogos/List.png",
    "DataClasses": ["Email addresses", "Passwords"],
    "IsVerified": false,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  }),
  BreachModel.fromJson({
    "Name": "Ticketfly",
    "Title": "Ticketfly",
    "Domain": "ticketfly.com",
    "BreachDate": "2018-05-31",
    "AddedDate": "2018-06-03T06:14:14Z",
    "ModifiedDate": "2018-07-14T06:06:15Z",
    "PwnCount": 26151608,
    "Description":
        "In May 2018, the website for the ticket distribution service <a href=\"https://motherboard.vice.com/en_us/article/mbk3nx/ticketfly-website-database-hacked-data-breach\" target=\"_blank\" rel=\"noopener\">Ticketfly was defaced by an attacker and was subsequently taken offline</a>. The attacker allegedly requested a ransom to share details of the vulnerability with Ticketfly but did not receive a reply and subsequently posted the breached data online to a publicly accessible location. The data included over 26 million unique email addresses along with names, physical addresses and phone numbers. Whilst there were no passwords in the publicly leaked data, <a href=https://support.ticketfly.com/customer/en/portal/articles/2941983-ticketfly-cyber-incident-update\" target=\"_blank\" rel=\"noopener\">Ticketfly later issued an incident update</a> and stated that &quot;It is possible, however, that hashed values of password credentials could have been accessed&quot;.",
    "LogoPath":
        "https://haveibeenpwned.com/Content/Images/PwnedLogos/Ticketfly.png",
    "DataClasses": [
      "Email addresses",
      "Names",
      "Phone numbers",
      "Physical addresses"
    ],
    "IsVerified": true,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  }),
  BreachModel.fromJson({
    "Name": "VerificationsIO",
    "Title": "Verifications.io",
    "Domain": "verifications.io",
    "BreachDate": "2019-02-25",
    "AddedDate": "2019-03-09T19:29:54Z",
    "ModifiedDate": "2019-03-09T20:49:51Z",
    "PwnCount": 763117241,
    "Description":
        "In February 2019, the email address validation service <a href=\"https://securitydiscovery.com/800-million-emails-leaked-online-by-email-verification-service\" target=\"_blank\" rel=\"noopener\">verifications.io suffered a data breach</a>. Discovered by <a href=\"https://twitter.com/mayhemdayone\" target=\"_blank\" rel=\"noopener\">Bob Diachenko</a> and <a href=\"https://twitter.com/vinnytroia\" target=\"_blank\" rel=\"noopener\">Vinny Troia</a>, the breach was due to the data being stored in a MongoDB instance left publicly facing without a password and resulted in 763 million unique email addresses being exposed. Many records within the data also included additional personal attributes such as names, phone numbers, IP addresses, dates of birth and genders. No passwords were included in the data. The Verifications.io website went offline during the disclosure process, although <a href=\"https://web.archive.org/web/20190227230352/https://verifications.io/\" target=\"_blank\" rel=\"noopener\">an archived copy remains viewable</a>.",
    "LogoPath":
        "https://haveibeenpwned.com/Content/Images/PwnedLogos/VerificationsIO.png",
    "DataClasses": [
      "Dates of birth",
      "Email addresses",
      "Employers",
      "Genders",
      "Geographic locations",
      "IP addresses",
      "Job titles",
      "Names",
      "Phone numbers",
      "Physical addresses"
    ],
    "IsVerified": true,
    "IsFabricated": false,
    "IsSensitive": false,
    "IsRetired": false,
    "IsSpamList": false
  })
];
