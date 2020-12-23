﻿&НаСервере
Перем ТекущаяГруппа, ТекущаяСтрока, ПроверяемоеЗначение, ЕстьПроблема, ЕстьОшибка;

&НаСервере
Перем HTTPСоединение, ТекущийКаталог, ИмяФайлаОбработки, ЕстьОшибкиПроблемы;

#Область СобытияФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	Параметры.Свойство("Автотестирование", Автотестирование);
	ОбработкаОбъект = РеквизитФормыВЗначение("Объект");
	ФайлОбработки = Новый Файл(ОбработкаОбъект.ИспользуемоеИмяФайла);
	ИмяФайлаОбработки = ФайлОбработки.Имя;
	ТекущийКаталог = ФайлОбработки.Путь;
	
	Если Автотестирование Тогда
		Попытка
			СоздатьСоединение();
			ВыполнитьТесты();
		Исключение
			Лог = Новый ЗаписьТекста(ТекущийКаталог + "autotest.log");
			Лог.ЗаписатьСтроку(ИнформацияОбОшибке().Описание);
			Лог.Закрыть();
		КонецПопытки;
	Иначе
		ВыполнитьТесты();
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	
	Если Автотестирование Тогда
		ПодключитьОбработчикОжидания("ЗавершитьРаботу", 1, Истина);
	Иначе
		Для каждого ЭлементСписка из СписокУзлов Цикл
			Элементы.Результаты.Развернуть(ЭлементСписка.Значение, Истина);
		КонецЦикла;
		СписокУзлов.Очистить();
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ЗавершитьРаботу()
	
	ЗавершитьРаботуСистемы(Ложь);
	
КонецПроцедуры

#КонецОбласти

#Область МетодыAppVeyor

&НаСервере
Процедура СоздатьСоединение()
	
	ЧтениеТекста = Новый ЧтениеТекста(ТекущийКаталог + "app_port.txt");
	Порт = Число(ЧтениеТекста.Прочитать());
	HTTPСоединение = Новый HTTPСоединение("localhost", Порт);
	
КонецПроцедуры

&НаСервере
Процедура ОтправитьСообщение(Сообщение, Статус, ПОдробно = "")
	
	Структура = Новый Структура;
	Структура.Вставить("message", Строка(Сообщение));
	Структура.Вставить("category", Строка(Статус));
	Структура.Вставить("details", Строка(ПОдробно));
	
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	ЗаписатьJSON(ЗаписьJSON, Структура);
	ТекстJSON = ЗаписьJSON.Закрыть();
	
	HTTPЗапрос = Новый HTTPЗапрос("/api/build/messages");
	HTTPЗапрос.УстановитьТелоИзСтроки(ТекстJSON);
	HTTPЗапрос.Заголовки.Вставить("Content-type", "application/json");
	HTTPСоединение.ОтправитьДляОбработки(HTTPЗапрос);
	
КонецПроцедуры

&НаСервере
Процедура ОтправитьТест(ИмяТеста, Длительность, Статус, Подробно = "")
	
	Структура = Новый Структура;
	Структура.Вставить("outcome", Статус);
	Структура.Вставить("testName", ИмяТеста);
	Структура.Вставить("fileName", ИмяФайлаОбработки);
	Структура.Вставить("ErrorMessage", Подробно);
	Структура.Вставить("durationMilliseconds", Длительность);
	
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	ЗаписатьJSON(ЗаписьJSON, Структура);
	ТекстJSON = ЗаписьJSON.Закрыть();
	
	HTTPЗапрос = Новый HTTPЗапрос("/api/tests");
	HTTPЗапрос.УстановитьТелоИзСтроки(ТекстJSON);
	HTTPЗапрос.Заголовки.Вставить("Content-type", "application/json");
	HTTPСоединение.ОтправитьДляОбработки(HTTPЗапрос);
	
КонецПроцедуры

#КонецОбласти

#Область ЭкспортныеМетоды

&НаСервере
Функция Тест(Знач Представление = "") Экспорт
	
	ТекущаяСтрока = ТекущаяГруппа.ПолучитьЭлементы().Добавить();
	ТекущаяСтрока.Наименование = Представление;
	ТекущаяСтрока.КартинкаСтрок = 1;
	Возврат ЭтаФорма;
	
КонецФункции	

&НаСервере
Функция Что(Знач Значение) Экспорт
	
	ПроверяемоеЗначение = Значение;
	ТекущаяСтрока.Результат = Значение;
	Возврат ЭтаФорма;
	
КонецФункции	

&НаСервере
Функция Значение() Экспорт
	
	Возврат ПроверяемоеЗначение;
	
КонецФункции	

&НаСервере
Функция ЗначениеJSON() Экспорт
	
	Если ПустаяСтрока(ПроверяемоеЗначение) Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	ПоляДаты = Новый Массив;
	ПоляДаты.Добавить("CreationDate");
	ПоляДаты.Добавить("date");
	
	ЧтениеJSON = Новый ЧтениеJSON();
	ЧтениеJSON.УстановитьСтроку(ПроверяемоеЗначение);
	Возврат ПрочитатьJSON(ЧтениеJSON, , ПоляДаты);
	
КонецФункции

&НаСервере
Функция Получить(Знач Имя) Экспорт
	
	Если ПустаяСтрока(ТекущаяСтрока.Наименование) Тогда
		ТекущаяСтрока.Наименование = "Получить свойство: " + Имя;
	КонецЕсли;
	
	ПроверяемоеЗначение = ПроверяемоеЗначение[Имя];
	ТекущаяСтрока.Результат = ПроверяемоеЗначение;
	Возврат ЭтаФорма;
	
КонецФункции	

&НаСервере
Функция Установить(Знач Имя, Знач Значение) Экспорт
	
	Если ПустаяСтрока(ТекущаяСтрока.Наименование) Тогда
		ТекущаяСтрока.Наименование = "Установить свойство: " + Имя;
	КонецЕсли;
	
	ТекущаяСтрока.Результат = Значение;
	ПроверяемоеЗначение[Имя] = Значение;
	Возврат ЭтаФорма;
	
КонецФункции	

&НаСервере
Функция ПолучитьФормулу(Знач Имя, Знач П1, Знач П2, Знач П3, Знач П4, Знач П5, Знач П6, Знач П7)
	
	Формула = "";
	Количество = 7;
	Для Номер = 0 по Количество - 1 Цикл
		ИмяПараметра = "П" + (Количество - Номер);
		Если Не ПустаяСтрока(Формула) Тогда
			Формула = "," + Формула;
		КонецЕсли;
		Если Вычислить(ИмяПараметра) <> "ПУСТО" Тогда
			Формула = ИмяПараметра + Формула;
		КонецЕсли;
	КонецЦикла;
	
	Возврат "ПроверяемоеЗначение." + Имя + "(" + Формула + ")";
	
КонецФункции	

&НаСервере
Функция Функц(Знач Имя, Знач П1 = "ПУСТО", Знач П2 = "ПУСТО", Знач П3 = "ПУСТО", Знач П4 = "ПУСТО", Знач П5 = "ПУСТО", Знач П6 = "ПУСТО", Знач П7 = "ПУСТО") Экспорт
	
	Если ПустаяСтрока(ТекущаяСтрока.Наименование) Тогда
		ТекущаяСтрока.Наименование = "Функция: " + Имя;
	КонецЕсли;
	
	Формула = ПолучитьФормулу(Имя, П1, П2, П3, П4, П5, П6, П7);
	ПроверяемоеЗначение = Вычислить(Формула);
	ТекущаяСтрока.Результат = ПроверяемоеЗначение;
	
	Возврат ЭтаФорма;
	
КонецФункции	

&НаСервере
Функция Проц(Знач Имя, Знач П1 = "ПУСТО", Знач П2 = "ПУСТО", Знач П3 = "ПУСТО", Знач П4 = "ПУСТО", Знач П5 = "ПУСТО", Знач П6 = "ПУСТО", Знач П7 = "ПУСТО") Экспорт
	
	Если ПустаяСтрока(ТекущаяСтрока.Наименование) Тогда
		ТекущаяСтрока.Наименование = "Процедура: " + Имя;
	КонецЕсли;
	
	Формула = ПолучитьФормулу(Имя, П1, П2, П3, П4, П5, П6, П7);
	Выполнить(Формула);
	
	Возврат ЭтаФорма;
	
КонецФункции	

&НаСервере
Функция Равно(Знач Значение) Экспорт
	
	ТекущаяСтрока.Эталон = Строка(Значение);
	Если ПроверяемоеЗначение <> Значение Тогда
		ЗаписатьПроблему("Проверяемое значение не соответствует эталону");
	КонецЕсли;
	
	Возврат ЭтаФорма;
	
КонецФункции	

&НаСервере
Функция ЕстьИстина() Экспорт
	
	ТекущаяСтрока.Эталон = "Значение = Истина";
	Если ПроверяемоеЗначение <> Истина Тогда
		ЗаписатьПроблему("Проверяемое значение есть ложь");
	КонецЕсли;
	
	Возврат ЭтаФорма;
	
КонецФункции	

&НаСервере
Функция ИмеетТип(Знач ТипИлиИмяТипа) Экспорт
	
	ОжидаемыйТип = ?(ТипЗнч(ТипИлиИмяТипа) = Тип("Строка"), Тип(ТипИлиИмяТипа), ТипИлиИмяТипа);
	ТекущаяСтрока.Эталон = "ТипЗнч(Значение) = Тип(""" + Строка(ТипИлиИмяТипа) + """)";
	ТипПроверяемогоЗначения = ТипЗнч(ПроверяемоеЗначение);
	Если ТипПроверяемогоЗначения <> ОжидаемыйТип Тогда
		Результат = "Неверный тип значения: " + ПроверяемоеЗначение;
		ЗаписатьПроблему(Результат);
	КонецЕсли;
	
	Возврат ЭтаФорма;
	
КонецФункции

&НаСервере
Функция Больше(Знач МеньшееЗначение) Экспорт
	
	ТекущаяСтрока.Эталон = "Значение > " + Строка(МеньшееЗначение);
	
	Если Не (ПроверяемоеЗначение > МеньшееЗначение) Тогда
		ЗаписатьПроблему("Проверяемое значение должно быть больше ");
	КонецЕсли;
	
	Возврат ЭтотОбъект;
	
КонецФункции

&НаСервере
Функция ЭтоКартинка(Знач Формат = Неопределено) Экспорт
	
	Если Формат = Неопределено Тогда
		Формат = ФорматКартинки.PNG;
	КонецЕсли;
	
	ПроверяемаяКартинка = Новый Картинка(ПроверяемоеЗначение);
	Если ПроверяемаяКартинка.Формат() <> ФорматКартинки.PNG Тогда
		ЗаписатьПроблему("Формат картинки не соответствует ожидаемому: " + ФорматКартинки.PNG);
	КонецЕсли;
	
	Возврат ЭтаФорма;
	
КонецФункции	

&НаСервере
Процедура ЗаписатьПроблему(ТекстПроблемы = "")

	ЕстьПроблема = Истина;
	ЕстьОшибкиПроблемы = Истина; 
	
	Если ТекущаяСтрока = Неопределено Тогда
		ТекущаяСтрока = ТекущаяГруппа.ПолучитьЭлементы().Добавить();
		ТекущаяСтрока.Наименование = "Неизвестная проблема";
	КонецЕсли;
	
	ТекущаяСтрока.Подробности = ТекстПроблемы;
	ТекущаяСтрока.КартинкаСтрок = 2;
	ТекущаяГруппа.КартинкаСтрок = 2;
	
	Если Автотестирование Тогда
		ОтправитьСообщение(ТекущаяСтрока.Наименование, "Warning", ТекстПроблемы);
	КонецЕсли;	
	
КонецПроцедуры

&НаСервере
Процедура ЗаписатьОшибку(Результат, Подробности)
	
	ЕстьОшибка = Истина;
	ЕстьОшибкиПроблемы = Истина; 
	
	Если ТекущаяСтрока = Неопределено Тогда
		ТекущаяСтрока = ТекущаяГруппа.ПолучитьЭлементы().Добавить();
		ТекущаяСтрока.Наименование = "Неизвестная ошибка";
	КонецЕсли;
	
	ТекущаяСтрока.Эталон = Результат;
	ТекущаяСтрока.Подробности = Подробности;
	ТекущаяСтрока.КартинкаСтрок = 3;
	ТекущаяГруппа.КартинкаСтрок = 3;
	
	Если Автотестирование Тогда
		ОтправитьСообщение(ТекущаяСтрока.Наименование, "Error", Подробности);
	КонецЕсли;	
	
КонецПроцедуры

&НаСервере
Процедура Добавить(Знач ИмяМетода, Знач Параметры = Неопределено, Знач Представление = "") Экспорт
	
	Если Не ЗначениеЗаполнено(Параметры) ИЛИ ТипЗнч(Параметры) <> Тип("Массив") Тогда
		Если ТипЗнч(Параметры) = Тип("Строка") И Представление = "" Тогда
			Представление = Параметры;
		КонецЕсли;
		Параметры = Неопределено;
	КонецЕсли;
	
	ТекущаяСтрока = Результаты.ПолучитьЭлементы().Добавить();
	ТекущаяСтрока.Наименование = Представление;
	ТекущаяСтрока.ИмяМетода = ИмяМетода;
	
	СписокУзлов.Добавить(ТекущаяСтрока.ПолучитьИдентификатор());
	
КонецПроцедуры

#КонецОбласти

&НаСервере
Процедура ВыполнитьТест(ОбработкаОбъект)
	
	ЕстьОшибка = Ложь;
	ЕстьПроблема = Ложь;
	
	ТекущаяСтрока = Неопределено;
	
	Попытка
		ТекущаяГруппа.КартинкаСтрок = 1;
		ВремяСтарта = ТекущаяУниверсальнаяДатаВМиллисекундах();
		Выполнить("ОбработкаОбъект." + ТекущаяГруппа.ИмяМетода + "()");
	Исключение
		Информация = ИнформацияОбОшибке();
		Результат = КраткоеПредставлениеОшибки(Информация);
		Подробности = ПодробноеПредставлениеОшибки(Информация);
		ЗаписатьОшибку(Результат, Подробности);
	КонецПопытки;
	
	Если Автотестирование Тогда
		Статус = ?(ЕстьОшибка, "Failed", ?(ЕстьПроблема, "Inconclusive", "Passed"));
		Длительность = ТекущаяУниверсальнаяДатаВМиллисекундах() - ВремяСтарта;
		ОтправитьТест(ТекущаяГруппа.Наименование, Длительность, Статус);
	КонецЕсли;
	
КонецПроцедуры	
 
&НаСервере
Процедура ВыполнитьТесты()
	
	ЕстьОшибкиПроблемы = Ложь;
	
	Результаты.ПолучитьЭлементы().Очистить();
	ОбработкаОбъект = РеквизитФормыВЗначение("Объект");
	ОбработкаОбъект.ЗаполнитьНаборТестов(ЭтаФорма);
	Для каждого ТекСтр из Результаты.ПолучитьЭлементы() Цикл
		ТекущаяГруппа = ТекСтр;
		ВыполнитьТест(ОбработкаОбъект);
	КонецЦикла;
	
	Если Автотестирование И НЕ ЕстьОшибкиПроблемы Тогда
		ЗаписьТекста = Новый ЗаписьТекста(ТекущийКаталог + "success.txt");
		ЗаписьТекста.ЗаписатьСтроку(ТекущаяУниверсальнаяДата());
		ЗаписьТекста.Закрыть();
	КонецЕсли;
	
КонецПроцедуры	

