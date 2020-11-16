## Общая информация по библиотеке VanessaExt

### Состав библиотеки
- <a href="WindowsControl.md">WindowsControl</a>
- <a href="ProcessControl.md">ProcessControl</a>
- <a href="ClipboardControl.md">ClipboardControl</a>
- <a href="GitFor1C.md">GitFor1C</a>

Внешние компоненты в составе библиотеки поддерживают как синхронный, так и асинхронный вызов.
Для асинхронного вызова в полном соответствии с документацией Синтакс-помощника
1С:Предприятие применяются методы:
- НачатьВызов<ИмяМетода>(<ОписаниеОповещения>, <Параметры>)
- НачатьПолучение<ИмяСвойства>(<ОписаниеОповещения>)

Пример асинхронного вызова внешней компоненты:
```bsl
&НаКлиенте
Процедура ПодключениеВнешнейКомпонентыЗавершение(Подключение, ДополнительныеПараметры) Экспорт
	ОписаниеОповещения = Новый ОписаниеОповещения("ПолученаВерсияКомпоненты", ЭтотОбъект);
	ВнешняяКомпонента.НачатьПолучениеВерсия(ОписаниеОповещения);
КонецПроцедуры

&НаКлиенте
Процедура ПолученаВерсияКомпоненты(Значение, ДополнительныеПараметры) Экспорт
	Заголовок = "Управление окнами, версия " + Значение;
КонецПроцедуры	
```

Все примеры будут приводиться для синхронных вызовов. В публикуемом примере
[**VanessaExt.epf**](https://github.com/lintest/VanessaExt/releases) используются только асинхронные вызовы.

Многие свойства и методы компоненты возвращают сложные типы данных, которые сериализованы 
в строку формата JSON. Поэтому имеет смысл объявить в вызывающем модуле универсальную 
функцию, которая будет использоваться ниже в примерах работы компоненты:
```bsl
Функция ПрочитатьСтрокуJSON(ТекстJSON)
	Если ПустаяСтрока(ТекстJSON) Тогда
		Возврат Неопределено;
	Иначе
		ПоляДаты = Новый Массив;
		ПоляДаты.Добавить("date");
		ПоляДаты.Добавить("CreationDate");
		ЧтениеJSON = Новый ЧтениеJSON();
		ЧтениеJSON.УстановитьСтроку(ТекстJSON);
		Возврат ПрочитатьJSON(ЧтениеJSON, , ПоляДаты);
	КонецЕсли;
КонецФункции
```

### Установка и подключение

В прилагаемом примере файлы внешней компоненты хранятся в макете **VanessaExt**, реквизит формы 
**МестоположениеКомпоненты** используется для передачи макета компоненты между сервером и клиентом.
Для установки и подключения внешней компоненты рекомендуется использовать следующий программный код:

```bsl
&НаКлиенте
Перем ИдентификаторКомпоненты, ВнешняяКомпонента;

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	МакетКомпоненты = РеквизитФормыВЗначение("Объект").ПолучитьМакет("VanessaExt");
	МестоположениеКомпоненты = ПоместитьВоВременноеХранилище(МакетКомпоненты, УникальныйИдентификатор);
КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	ИдентификаторКомпоненты = "_" + СтрЗаменить(Новый УникальныйИдентификатор, "-", "");
	ВыполнитьПодключениеВнешнейКомпоненты(Истина);
КонецПроцедуры

&НаКлиенте
Процедура ВыполнитьПодключениеВнешнейКомпоненты(ДополнительныеПараметры) Экспорт
	НачатьПодключениеВнешнейКомпоненты(
		Новый ОписаниеОповещения("ПодключениеВнешнейКомпонентыЗавершение", ЭтаФорма, ДополнительныеПараметры),
		МестоположениеКомпоненты, ИдентификаторКомпоненты, ТипВнешнейКомпоненты.Native); 
КонецПроцедуры	

&НаКлиенте
Процедура ПодключениеВнешнейКомпонентыЗавершение(Подключение, ДополнительныеПараметры) Экспорт
	Если Подключение Тогда
		ВнешняяКомпонента = Новый("AddIn." + ИдентификаторКомпоненты + ".WindowsControl");
	ИначеЕсли ДополнительныеПараметры = Истина Тогда
		ОписаниеОповещения = Новый ОписаниеОповещения("ВыполнитьПодключениеВнешнейКомпоненты", ЭтаФорма, Ложь);
		НачатьУстановкуВнешнейКомпоненты(ОписаниеОповещения, МестоположениеКомпоненты);
	КонецЕсли;
КонецПроцедуры	
```
***

<a href="BuildLibrary.md">Инструкция по самостоятельной сборке библиотеки</a>

При разработке использовались библиотеки:
- [cpp-c11-make-screenshot by Roman Shuvalov](https://github.com/Butataki/cpp-x11-make-screenshot)
- [Clip Library by David Capello](https://github.com/dacap/clip)
- [Boost C++ Libraries](https://www.boost.org/)