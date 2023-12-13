## 0.2.0

* Added **scriptCode** support in the **MapLocale** model. Thanks to **@dujiepeng** for the suggestion
* Refactor all **Locale** object to use **Locale.fromSubtags**
* Update some dependencies use to support the package

## 0.1.14

* Increase android minSdk support to 21 and add support to higher gradle build tools version

## 0.1.13

* Added **Strings Util** and **Context Extension** for helping with localization text. Check the readme page at
  the [Some update note] section.

## 0.1.12

* Add **LocaleExtension** for getting the locale identifier (en_US, km_KH, ja_JP, ect)

## 0.1.11

* Add **fontFamily** param in **MapLocale** model for providing font family for each language (this field is optional)
* Update some dependencies use to support the package

## 0.1.10

* Update some dependencies use to support the package

## 0.1.9

* Fixed missing **web** plugin support
* Updated README documentation

## 0.1.8

* Remove **getString** method from **FlutterLocalization** class
* **getString** extension now required **context** parameter

## 0.1.7

* Added string extension for more easy use of the **getString** function

## 0.1.6

* Update some dependencies use to support the package
* Remove the required context in **getString()** method

## 0.1.5

* Add condition to the **translate()** function to prevent it recall on the same provided **languageCode**
* Update some dependencies use to support the package
* Small make-change on **example** file

## 0.1.4

* I have found some issues and a little bit of low performance when using the **load from json file** method, so I
  decided to remove it for better usage
* Remove the old **init()** function and rename the **initWithMap()** to **init()** instead

## 0.1.3

* Optimize some code and allowed the **onTranslatedLanguage** callback to be null. Thanks to **@Hasankanso** for the
  suggestion
* NOTE: **init()** function will be removed soon for better load time and performance, please use **initWithMap()**
  instead

## 0.1.2

* Update some dependencies use to support the package and README document

## 0.1.1

* Add plugin for web support

## 0.1.0

* Migrate to support null-safety

## 0.0.12

* Update some dependencies use to support the package

## 0.0.11

* Add the possibility to do localization with **Map<String, dynamic>** instead of **json file**. Check the **README** or
  **example** for more information with the **initWithMap()** function

## 0.0.10

* Solve the problem where **currentLocale** is null when try to call at the **main.dart** (after **initState()**)

## 0.0.9

* Nothing new, just refactor some code and performance

## 0.0.8

* Rollback change on *0.0.7* which cause problem to the localization process

## 0.0.7

* Add possibility to add more custom delegate at the **init()** function

## 0.0.6

* Added get language name feature
* In **init()** function, rename **languageCodes** to **supportedLanguageCodes**
* Added **save** parameter in **translate()** function, so you can decide to save the cache or not

## 0.0.5

* Fix bug where the initLanguageCode in **init()** function is not working

## 0.0.4

* Add language cache (the selected language will save and load when the app is open)

## 0.0.3

* Drop down the sdk and flutter version support

## 0.0.2

* Provide more documents and code comments

## 0.0.1

* First version of the package