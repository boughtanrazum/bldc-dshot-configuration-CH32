extends Node2D

@onready var mcu_select: OptionButton = find_child("McuSelect", true, false)
@onready var generate_button: Button = find_child("GenerateButton", true, false)
@onready var message_log: RichTextLabel = find_child("MessageLog", true, false)

@onready var bldc_timer_select: OptionButton = find_child("BLDCTimerSelect", true, false)
@onready var bldc_remap_select: OptionButton = find_child("BLDCRemapSelect", true, false)
@onready var bldc_remap_info: Label = find_child("BLDCRemapInfo", true, false)
@onready var bldc_psc_spin: SpinBox = find_child("BLDCPscSpin", true, false)
@onready var bldc_period_spin: SpinBox = find_child("BLDCPeriodSpin", true, false)
@onready var bldc_fast_irq: CheckBox = find_child("BLDCFastIrqCheck", true, false)
@onready var bldc_custom_pins_check: CheckBox = find_child("BLDCCustomPinsCheck", true, false)

@onready var bldc_port_u_select: OptionButton = find_child("BLDC_PortU_Select", true, false)
@onready var bldc_pin_u_select: OptionButton = find_child("BLDC_PinU_Select", true, false)
@onready var bldc_port_v_select: OptionButton = find_child("BLDC_PortV_Select", true, false)
@onready var bldc_pin_v_select: OptionButton = find_child("BLDC_PinV_Select", true, false)
@onready var bldc_port_w_select: OptionButton = find_child("BLDC_PortW_Select", true, false)
@onready var bldc_pin_w_select: OptionButton = find_child("BLDC_PinW_Select", true, false)

@onready var dshot_timer_select: OptionButton = find_child("DSHOTTimerSelect", true, false)
@onready var dshot_remap_select: OptionButton = find_child("DSHOTRemapSelect", true, false)
@onready var dshot_remap_info: Label = find_child("DSHOTRemapInfo", true, false)
@onready var dshot_speed_select: OptionButton = find_child("DSHOTSpeedSelect", true, false)
@onready var dshot_bidir_check: CheckBox = find_child("DSHOTBidirCheck", true, false)
@onready var dshot_edt_check: CheckBox = find_child("DSHOTEdtCheck", true, false)
@onready var dshot_fast_irq: CheckBox = find_child("DSHOTFastIrqCheck", true, false)

var mcu_database = {}
var current_mcu_data = {}
var current_mcu_name = ""

var bldc_pins = []
var dshot_pins = []
var comparator_pins = []

var custom_comparator_pins = false

var save_dir_path: String = ""
var _pending_config_h: String = ""
var _pending_config_2_h: String = ""

func _ready():
	print("=== Инициализация программы ===")
	
	check_nodes()
	load_mcu_data()
	connect_signals()
	
	if mcu_select and mcu_select.item_count > 0:
		mcu_select.select(0)
		_on_mcu_changed(0)
	
	print("=== Программа готова к работе ===")

func check_nodes():
	print("--- Проверка нод интерфейса ---")
	
	var nodes_to_check = {
		"mcu_select": mcu_select,
		"generate_button": generate_button,
		"message_log": message_log,
		"bldc_timer_select": bldc_timer_select,
		"bldc_remap_select": bldc_remap_select,
		"bldc_remap_info": bldc_remap_info,
		"bldc_psc_spin": bldc_psc_spin,
		"bldc_period_spin": bldc_period_spin,
		"bldc_fast_irq": bldc_fast_irq,
		"bldc_custom_pins_check": bldc_custom_pins_check,
		"bldc_port_u_select": bldc_port_u_select,
		"bldc_pin_u_select": bldc_pin_u_select,
		"bldc_port_v_select": bldc_port_v_select,
		"bldc_pin_v_select": bldc_pin_v_select,
		"bldc_port_w_select": bldc_port_w_select,
		"bldc_pin_w_select": bldc_pin_w_select,
		"dshot_timer_select": dshot_timer_select,
		"dshot_remap_select": dshot_remap_select,
		"dshot_remap_info": dshot_remap_info,
		"dshot_speed_select": dshot_speed_select,
		"dshot_bidir_check": dshot_bidir_check,
		"dshot_edt_check": dshot_edt_check,
		"dshot_fast_irq": dshot_fast_irq,
	}
	
	for node_name in nodes_to_check:
		if nodes_to_check[node_name] == null:
			printerr("  ❌ НЕ НАЙДЕНА НОДА: " + node_name)
		else:
			print("  ✓ Нода найдена: " + node_name)
	
	print("--- Проверка завершена ---")

func connect_signals():
	_safe_connect(mcu_select, "item_selected", _on_mcu_changed)
	_safe_connect(generate_button, "pressed", _on_generate_pressed)
	
	_safe_connect(bldc_timer_select, "item_selected", _on_bldc_timer_changed)
	_safe_connect(bldc_remap_select, "item_selected", _on_bldc_remap_changed)
	_safe_connect(bldc_custom_pins_check, "toggled", _on_custom_pins_toggled)
	
	_safe_connect(bldc_port_u_select, "item_selected", _on_comparator_changed)
	_safe_connect(bldc_pin_u_select, "item_selected", _on_comparator_changed)
	_safe_connect(bldc_port_v_select, "item_selected", _on_comparator_changed)
	_safe_connect(bldc_pin_v_select, "item_selected", _on_comparator_changed)
	_safe_connect(bldc_port_w_select, "item_selected", _on_comparator_changed)
	_safe_connect(bldc_pin_w_select, "item_selected", _on_comparator_changed)
	
	_safe_connect(dshot_timer_select, "item_selected", _on_dshot_timer_changed)
	_safe_connect(dshot_remap_select, "item_selected", _on_dshot_remap_changed)

func _safe_connect(obj, signal_name: String, callable: Callable):
	if obj and obj.has_signal(signal_name):
		if not obj.is_connected(signal_name, callable):
			obj.connect(signal_name, callable)

func _get_selected_text(btn: OptionButton, default: String = "") -> String:
	if not btn or btn.item_count <= 0:
		return default
	var idx = btn.selected
	if idx < 0 or idx >= btn.item_count:
		return default
	return btn.get_item_text(idx)

func _get_selected_index(btn: OptionButton, default: int = 0) -> int:
	if not btn or btn.item_count <= 0:
		return default
	var idx = btn.selected
	if idx < 0 or idx >= btn.item_count:
		return default
	return idx

func _set_comparator_pins_enabled(enabled: bool):
	for select in [bldc_port_u_select, bldc_pin_u_select, 
				   bldc_port_v_select, bldc_pin_v_select,
				   bldc_port_w_select, bldc_pin_w_select]:
		if select:
			select.disabled = not enabled
	
	if enabled:
		print("Компараторные пины разблокированы (ручной режим)")
	else:
		print("Компараторные пины заблокированы (авто из Remap)")

func _on_custom_pins_toggled(button_pressed: bool):
	custom_comparator_pins = button_pressed
	_set_comparator_pins_enabled(button_pressed)
	
	if not button_pressed:
		var timer_name = _get_selected_text(bldc_timer_select)
		var timer = current_mcu_data.timers.get(timer_name, {})
		if not timer.is_empty():
			var remap_idx = _get_selected_index(bldc_remap_select, 0)
			if timer.remaps.size() > remap_idx:
				_auto_set_comparator_pins_from_remap(timer.remaps[remap_idx])
	
	update_comparator_pins()
	validate_all()

func _auto_set_comparator_pins_from_remap(remap):
	var ch1_pin = ""
	var ch2_pin = ""
	var ch3_pin = ""
	
	for pin_desc in remap.pins:
		var parts = pin_desc.split("=")
		if parts.size() >= 2:
			var chan = parts[0].strip_edges()
			var pin_name = parts[1].strip_edges()
			
			if chan == "CH1":
				ch1_pin = pin_name
			elif chan == "CH2":
				ch2_pin = pin_name
			elif chan == "CH3":
				ch3_pin = pin_name
	
	if ch1_pin != "":
		_set_pin_from_string(bldc_port_u_select, bldc_pin_u_select, ch1_pin)
	if ch2_pin != "":
		_set_pin_from_string(bldc_port_v_select, bldc_pin_v_select, ch2_pin)
	if ch3_pin != "":
		_set_pin_from_string(bldc_port_w_select, bldc_pin_w_select, ch3_pin)

func _set_pin_from_string(port_select: OptionButton, pin_select: OptionButton, pin_str: String):
	if not port_select or not pin_select:
		return
	
	var port = ""
	var pin_num = ""
	
	var p_index = pin_str.find("P")
	if p_index >= 0:
		var after_p = pin_str.substr(p_index + 1)
		for i in range(after_p.length()):
			if after_p[i].is_valid_int():
				port = after_p.substr(0, i)
				pin_num = after_p.substr(i)
				break
	
	if port == "" or pin_num == "":
		print("⚠ Не удалось распарсить пин: " + pin_str)
		return
	
	for i in range(port_select.item_count):
		if port_select.get_item_text(i) == port:
			port_select.select(i)
			break
	
	for i in range(pin_select.item_count):
		if pin_select.get_item_text(i) == pin_num:
			pin_select.select(i)
			break
	
	print("Установлен компараторный пин: P" + port + pin_num)

func load_mcu_data():
	var files = ["ch32v003.json", "ch32v203.json"]
	
	for fn in files:
		if not FileAccess.file_exists("res://" + fn):
			printerr("❌ Файл не найден: res://" + fn)
			continue
		
		var file = FileAccess.open("res://" + fn, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var err = json.parse(text)
			if err == OK:
				var key = fn.replace(".json", "").to_upper()
				mcu_database[key] = json.data
				print("✓ Загружен файл данных: " + fn + " -> " + key)
			else:
				printerr("❌ Ошибка парсинга JSON: " + fn)

func _on_mcu_changed(_idx):
	if not mcu_select:
		return
	
	current_mcu_name = _get_selected_text(mcu_select)
	current_mcu_data = mcu_database.get(current_mcu_name, {})
	
	print("Выбран МК: " + current_mcu_name)
	
	if bldc_timer_select:
		bldc_timer_select.clear()
	if dshot_timer_select:
		dshot_timer_select.clear()
	
	if current_mcu_data.is_empty():
		add_message("[color=red]ОШИБКА: Данные для МК не найдены![/color]")
		return
	
	if bldc_timer_select and dshot_timer_select:
		for timer_name in current_mcu_data.timers:
			var t = current_mcu_data.timers[timer_name]
			if t.extended:
				bldc_timer_select.add_item(timer_name)
			dshot_timer_select.add_item(timer_name)
	
	populate_comparator_pins_all()
	
	if bldc_custom_pins_check:
		bldc_custom_pins_check.button_pressed = false
	custom_comparator_pins = false
	_set_comparator_pins_enabled(false)
	
	if bldc_timer_select and bldc_timer_select.item_count > 0:
		bldc_timer_select.select(0)
		_on_bldc_timer_changed(0)
	
	if dshot_timer_select and dshot_timer_select.item_count > 1:
		dshot_timer_select.select(1)
		_on_dshot_timer_changed(1)
	elif dshot_timer_select and dshot_timer_select.item_count > 0:
		dshot_timer_select.select(0)
		_on_dshot_timer_changed(0)
	
	update_comparator_pins()
	validate_all()

func populate_comparator_pins_all():
	var ports = ["A", "B", "C", "D", "E", "F"]
	
	for select in [bldc_port_u_select, bldc_port_v_select, bldc_port_w_select]:
		if not select:
			continue
		select.clear()
		for port in ports:
			select.add_item(port)
		if select.item_count > 3:
			select.select(3)
		elif select.item_count > 0:
			select.select(0)
	
	for select in [bldc_pin_u_select, bldc_pin_v_select, bldc_pin_w_select]:
		if not select:
			continue
		select.clear()
		for pin_num in range(16):
			select.add_item(str(pin_num))

func _on_bldc_timer_changed(_idx):
	if not bldc_timer_select or not bldc_remap_select:
		return
	
	var timer_name = _get_selected_text(bldc_timer_select)
	print("BLDC: выбран таймер " + timer_name)
	
	bldc_remap_select.clear()
	bldc_pins.clear()
	
	var timer = current_mcu_data.timers.get(timer_name, {})
	if timer.is_empty():
		if bldc_remap_info:
			bldc_remap_info.text = "(нет данных)"
		return
	
	for remap in timer.remaps:
		bldc_remap_select.add_item("Remap " + str(remap.index))
	
	if bldc_remap_select.item_count > 0:
		bldc_remap_select.select(0)
		_on_bldc_remap_changed(0)
	else:
		if bldc_remap_info:
			bldc_remap_info.text = "(нет данных)"
	
	validate_all()

func _on_bldc_remap_changed(_idx):
	if not bldc_timer_select:
		return
	
	var timer_name = _get_selected_text(bldc_timer_select)
	var timer = current_mcu_data.timers.get(timer_name, {})
	
	if timer.is_empty():
		return
	
	var remap_idx = _get_selected_index(bldc_remap_select, 0)
	bldc_pins.clear()
	
	if timer.remaps.size() > remap_idx:
		var remap = timer.remaps[remap_idx]
		var pins_text = "Пины таймера: "
		
		for pin_desc in remap.pins:
			var parts = pin_desc.split("=")
			if parts.size() >= 2:
				var pin_name = parts[1].strip_edges()
				bldc_pins.append(pin_name)
				pins_text += pin_desc + "  "
		
		if bldc_remap_info:
			bldc_remap_info.text = pins_text + "\n[Компараторы: авто из Remap]" if not custom_comparator_pins else pins_text + "\n[Компараторы: ручной режим]"
		
		if not custom_comparator_pins:
			_auto_set_comparator_pins_from_remap(remap)
		
		print("BLDC: выбран remap " + str(remap_idx) + ", пины таймера: " + str(bldc_pins))
	else:
		if bldc_remap_info:
			bldc_remap_info.text = "(нет данных)"
	
	validate_all()

func _on_dshot_timer_changed(_idx):
	if not dshot_timer_select or not dshot_remap_select:
		return
	
	var timer_name = _get_selected_text(dshot_timer_select)
	print("DSHOT: выбран таймер " + timer_name)
	
	dshot_remap_select.clear()
	dshot_pins.clear()
	
	var timer = current_mcu_data.timers.get(timer_name, {})
	if timer.is_empty():
		if dshot_remap_info:
			dshot_remap_info.text = "(нет данных)"
		return
	
	for remap in timer.remaps:
		dshot_remap_select.add_item("Remap " + str(remap.index))
	
	if dshot_remap_select.item_count > 0:
		dshot_remap_select.select(0)
		_on_dshot_remap_changed(0)
	else:
		if dshot_remap_info:
			dshot_remap_info.text = "(нет данных)"
	
	validate_all()

func _on_dshot_remap_changed(_idx):
	if not dshot_timer_select:
		return
	
	var timer_name = _get_selected_text(dshot_timer_select)
	var timer = current_mcu_data.timers.get(timer_name, {})
	
	if timer.is_empty():
		return
	
	var remap_idx = _get_selected_index(dshot_remap_select, 0)
	dshot_pins.clear()
	
	if timer.remaps.size() > remap_idx:
		var remap = timer.remaps[remap_idx]
		var pins_text = "Пины таймера: "
		
		for pin_desc in remap.pins:
			var parts = pin_desc.split("=")
			if parts.size() >= 2:
				var chan = parts[0].strip_edges()
				var pin_name = parts[1].strip_edges()
				
				if chan == "CH1":
					dshot_pins.append(pin_name)
				
				pins_text += pin_desc + "  "
		
		if dshot_remap_info:
			dshot_remap_info.text = pins_text
		print("DSHOT: выбран remap " + str(remap_idx) + ", CH1 пин: " + str(dshot_pins))
	else:
		if dshot_remap_info:
			dshot_remap_info.text = "(нет данных)"
	
	validate_all()

func _on_comparator_changed(_idx):
	update_comparator_pins()
	validate_all()

func update_comparator_pins():
	comparator_pins.clear()
	
	var pins_data = [
		[bldc_port_u_select, bldc_pin_u_select],
		[bldc_port_v_select, bldc_pin_v_select],
		[bldc_port_w_select, bldc_pin_w_select]
	]
	
	for data in pins_data:
		var port_select = data[0]
		var pin_select = data[1]
		
		if not port_select or not pin_select:
			continue
		
		var port = _get_selected_text(port_select)
		var pin_num = _get_selected_text(pin_select)
		
		if port == "" or pin_num == "":
			continue
		
		var pin_name = "P" + port + pin_num
		comparator_pins.append(pin_name)
	
	print("Компараторные пины: " + str(comparator_pins))

func validate_all():
	if not message_log:
		return
	
	message_log.clear()
	update_comparator_pins()
	
	var bldc_timer = _get_selected_text(bldc_timer_select)
	var dshot_timer = _get_selected_text(dshot_timer_select)
	
	var has_errors = false
	var has_warnings = false
	
	add_message("[b]📋 Проверка конфигурации для " + current_mcu_name + "[/b]")
	add_message("")
	
	if bldc_timer != "" and dshot_timer != "" and bldc_timer == dshot_timer:
		add_message("[color=red]❌ ОШИБКА: Таймер " + bldc_timer + " используется одновременно для BLDC и DSHOT![/color]")
		has_errors = true
	
	for dshot_pin in dshot_pins:
		if dshot_pin in comparator_pins:
			add_message("[color=red]❌ ОШИБКА: Пин " + dshot_pin + " используется и для DSHOT (CH1), и как компараторный пин BLDC![/color]")
			has_errors = true
	
	for dshot_pin in dshot_pins:
		if dshot_pin in bldc_pins:
			add_message("[color=yellow]⚠ ПРЕДУПРЕЖДЕНИЕ: Пин " + dshot_pin + " (DSHOT CH1) пересекается с пином таймера BLDC![/color]")
			has_warnings = true
	
	for comp_pin in comparator_pins:
		if comp_pin in bldc_pins:
			add_message("[color=yellow]⚠ ПРЕДУПРЕЖДЕНИЕ: Компараторный пин " + comp_pin + " пересекается с пином таймера BLDC![/color]")
			has_warnings = true
	
	if comparator_pins.size() >= 3:
		if comparator_pins[0] == comparator_pins[1] or comparator_pins[0] == comparator_pins[2] or comparator_pins[1] == comparator_pins[2]:
			add_message("[color=red]❌ ОШИБКА: Компараторные пины не могут повторяться![/color]")
			has_errors = true
	
	add_message("")
	
	if not has_errors and not has_warnings:
		add_message("[color=green]✅ Конфигурация корректна. Можно генерировать файлы.[/color]")
	elif has_errors:
		add_message("[color=red]⚠ Обнаружены ошибки! Генерация невозможна.[/color]")
	else:
		add_message("[color=yellow]⚠ Обнаружены предупреждения. Рекомендуется проверить.[/color]")
	
	add_message("")
	add_message("[b]Текущие настройки:[/b]")
	
	var comp_mode = "РУЧНОЙ" if custom_comparator_pins else "АВТО из Remap"
	
	add_message("[color=cyan]▸ BLDC:[/color]")
	add_message("    Таймер: " + bldc_timer + " (расширенный)")
	add_message("    Remap: " + str(_get_selected_index(bldc_remap_select, 0)))
	add_message("    Пины таймера: " + str(bldc_pins))
	add_message("    Режим компараторов: " + comp_mode)
	add_message("    Компараторные пины: " + str(comparator_pins))
	add_message("    PSC: " + str(int(bldc_psc_spin.value) if bldc_psc_spin else "3") + 
			   ", Period: " + str(int(bldc_period_spin.value) if bldc_period_spin else "512"))
	add_message("    Быстрые прерывания: " + ("ДА" if (bldc_fast_irq and bldc_fast_irq.button_pressed) else "НЕТ"))
	
	add_message("[color=cyan]▸ DSHOT:[/color]")
	add_message("    Таймер: " + dshot_timer)
	add_message("    Remap: " + str(_get_selected_index(dshot_remap_select, 0)))
	add_message("    Пины таймера (CH1): " + str(dshot_pins))
	add_message("    Скорость: " + _get_selected_text(dshot_speed_select, "300") + " Kbps")
	add_message("    Двунаправленный: " + ("ДА" if (dshot_bidir_check and dshot_bidir_check.button_pressed) else "НЕТ"))
	add_message("    Расширенная телеметрия: " + ("ДА" if (dshot_edt_check and dshot_edt_check.button_pressed) else "НЕТ"))
	add_message("    Быстрые прерывания: " + ("ДА" if (dshot_fast_irq and dshot_fast_irq.button_pressed) else "НЕТ"))

func add_message(text: String):
	if message_log:
		message_log.append_text(text + "\n")

func _on_generate_pressed():
	if not message_log:
		return
	
	message_log.clear()
	
	var bldc_timer = _get_selected_text(bldc_timer_select)
	var dshot_timer = _get_selected_text(dshot_timer_select)
	
	if bldc_timer == "":
		add_message("[color=red]❌ ОШИБКА: Не выбран таймер для BLDC![/color]")
		return
	
	if dshot_timer == "":
		add_message("[color=red]❌ ОШИБКА: Не выбран таймер для DSHOT![/color]")
		return
	
	if bldc_timer == dshot_timer:
		add_message("[color=red]❌ ОШИБКА: Устраните конфликт таймеров перед генерацией![/color]")
		return
	
	if has_critical_errors():
		add_message("[color=red]❌ ОШИБКА: Устраните критические конфликты пинов перед генерацией![/color]")
		return
	
	var config_h = generate_bldc_config(bldc_timer)
	var config_2_h = generate_dshot_config(dshot_timer)
	
	_show_save_dialog(config_h, config_2_h)

func _show_save_dialog(config_h: String, config_2_h: String):
	_pending_config_h = config_h
	_pending_config_2_h = config_2_h
	
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.title = "Выберите папку для сохранения конфигурации"
	dialog.size = Vector2(800, 600)
	dialog.dir_selected.connect(_on_folder_selected)
	dialog.canceled.connect(_on_dialog_cancelled)
	
	if save_dir_path != "":
		dialog.current_dir = save_dir_path
	else:
		dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	add_child(dialog)
	dialog.popup_centered()

func _on_folder_selected(path: String):
	save_dir_path = path
	
	var path1 = path + "/config.h"
	var path2 = path + "/config-2.h"
	
	add_message("[b]📁 Сохранение файлов конфигурации[/b]")
	add_message("")
	
	if save_file(path1, _pending_config_h):
		add_message("[color=green]✅ config.h успешно сохранён![/color]")
		add_message("    Путь: " + path1)
	else:
		add_message("[color=red]❌ Ошибка сохранения config.h![/color]")
	
	add_message("")
	
	if save_file(path2, _pending_config_2_h):
		add_message("[color=green]✅ config-2.h успешно сохранён![/color]")
		add_message("    Путь: " + path2)
	else:
		add_message("[color=red]❌ Ошибка сохранения config-2.h![/color]")
	
	add_message("")
	add_message("[color=green]✅ Генерация завершена успешно![/color]")

func _on_dialog_cancelled():
	add_message("[color=yellow]⚠ Генерация отменена пользователем.[/color]")

func has_critical_errors() -> bool:
	for dshot_pin in dshot_pins:
		if dshot_pin in comparator_pins:
			return true
	
	if comparator_pins.size() >= 3:
		if comparator_pins[0] == comparator_pins[1] or comparator_pins[0] == comparator_pins[2] or comparator_pins[1] == comparator_pins[2]:
			return true
	
	return false

func generate_bldc_config(timer_name: String) -> String:
	var timer_num = int(timer_name.replace("TIM", ""))
	var remap = _get_selected_index(bldc_remap_select, 0)
	var psc = int(bldc_psc_spin.value) if bldc_psc_spin else 3
	var period = int(bldc_period_spin.value) if bldc_period_spin else 512
	var fast_irq = 1 if (bldc_fast_irq and bldc_fast_irq.button_pressed) else 0
	
	var port_u = _get_selected_text(bldc_port_u_select, "D")
	var pin_u = int(_get_selected_text(bldc_pin_u_select, "3"))
	var port_v = _get_selected_text(bldc_port_v_select, "D")
	var pin_v = int(_get_selected_text(bldc_pin_v_select, "5"))
	var port_w = _get_selected_text(bldc_port_w_select, "D")
	var pin_w = int(_get_selected_text(bldc_pin_w_select, "6"))
	
	var float_port = port_u if (port_u == port_v and port_u == port_w) else "D"
	
	var result = """#define BLDC_DemagDelay         1   ///< Задержка размагнитезации
#define BLDC_ToggleDelay        15  ///< Угол задержки переключения состояний выводов инвертора 

#define BLDC_x_FLOAT_PORT   {port}       ///< Порт подключенных выводов компараторов
#define BLDC_U_FLOAT_PIN    {u_pin}       ///< Порт вывода компаратора фазы U
#define BLDC_V_FLOAT_PIN    {v_pin}       ///< Порт вывода компаратора фазы V
#define BLDC_W_FLOAT_PIN    {w_pin}       ///< Порт вывода компаратора фазы W

#define BLDC_TIMER_NUM          {timer_num}       ///< Номер используемого расширенного таймера микроконтроллера 
#define BLDC_TIMER_PSC          {psc}           ///< Делитель частоты таймера 
#define BLDC_TIMER_PERIOD       {period}     ///< Количество тактов в периоде таймера (разрядность импульса ШИМ)
#define BLDC_TIMER_REMAP_NUM    {remap}       ///< Конфигурация выводов таймера

#define BLDC_TIMER_UP_IRQ_Prior     0   ///< Приоритет обработки прерываний драйвера
#define BLDC_USE_TIMER_UP_FAST_IRQ  {fast_irq}   ///< Использовать быструю обработку прерываний драйвера
#define BLDC_TIMER_UP_FAST_IRQ_NUM  0   ///< Номер канала быстрой обработки прерываний
""".format({
		"port": float_port,
		"u_pin": pin_u,
		"v_pin": pin_v,
		"w_pin": pin_w,
		"timer_num": timer_num,
		"psc": psc,
		"period": period,
		"remap": remap,
		"fast_irq": fast_irq
	})
	
	return result

func generate_dshot_config(timer_name: String) -> String:
	var timer_num = int(timer_name.replace("TIM", ""))
	var remap = _get_selected_index(dshot_remap_select, 0)
	var speed = int(_get_selected_text(dshot_speed_select, "300"))
	var bidir = 1 if (dshot_bidir_check and dshot_bidir_check.button_pressed) else 0
	var edt = 1 if (dshot_edt_check and dshot_edt_check.button_pressed) else 0
	var fast_irq = 1 if (dshot_fast_irq and dshot_fast_irq.button_pressed) else 0
	
	var result = """#define DSHOT_SPEED {speed}                 ///< Скорость протокола DSHOT (150, 300, 600, 1200)
#define DSHOT_BIDIR {bidir}                   ///< Использовать двунаправленный DSHOT
#define DSHOT_EDT   {edt}                   ///< Использовать расширенную телеметрию

#define DSHOT_TIMER_NUM         {timer_num}       ///< Номер используемого таймера микроконтроллера
#define DSHOT_TIMER_REMAP_NUM   {remap}       ///< Конфигурация выводов таймера

#define DSHOT_TIMER_IRQ_Prior       1   ///< Приоритет обработки прерываний драйвера
#define DSHOT_USE_TIMER_FAST_IRQ    {fast_irq}   ///< Использовать быструю обработку прерываний драйвера
#define DSHOT_TIMER_FAST_IRQ_NUM    1   ///< Номер канала быстрой обработки прерываний
""".format({
		"speed": speed,
		"bidir": bidir,
		"edt": edt,
		"timer_num": timer_num,
		"remap": remap,
		"fast_irq": fast_irq
	})
	
	return result

func save_file(path: String, content: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("Файл сохранён: " + path)
		return true
	else:
		printerr("Не удалось сохранить файл: " + path)
		return false
