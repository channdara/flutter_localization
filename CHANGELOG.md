## 0.1.10
* update some dependencies use to support the package
## 0.1.9
* fixed missing **web** plugin support
* updated README documentation
## 0.1.8
* remove **getString** method from **FlutterLocalization** class
* **getString** extension now required **context** parameter
## 0.1.7
* added string extension for more easy use of the **getString** function
## 0.1.6
* update some dependencies use to support the package
* remove the required context in **getString()** method
## 0.1.5
* add condition to the **translate()** function to prevent it recall on the same provided **languageCode**
* update some dependencies use to support the package
* small make-change on **example** file
## 0.1.4
* I have found some issues and a little bit low performance when using the **load from json file** method, so I decided to remove it for better usage
* remove the old **init()** function and rename the **initWithMap()** to **init()** instead
## 0.1.3
* optimize some code and allowed the **onTranslatedLanguage** callback to be null. Thank to **@Hasankanso** for the suggestion
* NOTE: **init()** function will be remove soon for better load time and performance, please use **initWithMap()** instead
## 0.1.2
* update some dependencies use to support the package and README document
## 0.1.1
* add plugin for web support
## 0.1.0
* migrate to support null-safety
## 0.0.12
* update some dependencies use to support the package
## 0.0.11
* add the possibility to do localization with **Map<String, dynamic>** instead of **json file**. Check the **README** or **example** for more information with the **initWithMap()** function
## 0.0.10
* solve the problem where **currentLocale** is null when try to call at the **main.dart** (after **initState()**)
## 0.0.9
* nothing new, just refactor some code and performance
## 0.0.8
* rollback change on *0.0.7* which cause problem to the localization process
## 0.0.7
* add possibility to add more custom delegate at the **init()** function
## 0.0.6
* added get language name feature
* in **init()** function, rename **languageCodes** to **supportedLanguageCodes**
* added **save** parameter in **translate()** function, so you can decide to save the cache or not
## 0.0.5
* fix bug where the initLanguageCode in **init()** function is not working
## 0.0.4
* add language cache (the selected language will save and load when the app is open)
## 0.0.3
* drop down the sdk and flutter version support
## 0.0.2
* provide more documents and code comments
## 0.0.1
* first version of the package