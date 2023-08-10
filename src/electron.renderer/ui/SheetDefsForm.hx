package ui;

import cdb.Data.ColumnType;
import haxe.Json;
import ui.modal.dialog.TextEditor;
import cdb.Data.Column;

class SheetDefsForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	public var jWrapper : js.jquery.JQuery;
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jWrapper.find("ul.rowList");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWrapper.find("dl.form");
	var sheet : cdb.Sheet;
	var curLine : Null<Dynamic>;


	public function new(sheet:cdb.Sheet) {
		this.sheet = sheet;
		this.curLine = sheet.lines[0];

		jWrapper = new J('<div class="sheetDefsForm"/>');
		jWrapper.html( JsTools.getHtmlTemplate("sheetDefsForm"));
		jWrapper.width("750px");
		
		jWrapper.find(".createRow").click(e -> {
			var l = sheet.newLine();
			selectLine(l);
		});
		jWrapper.find(".createColumn").click(e -> {
			// sheet.addColumn()
			new ui.modal.dialog.CastleColumn(sheet, (c) -> {
				updateForm();
			});
		});

		updateList();
		updateForm();
	}
	public function selectLine(line) {
		curLine = line;
		updateList();
		updateForm();
	}

	public function updateList(){
		jList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jList);
		var jSubList = new J('<ul/>');
		jSubList.appendTo(jLi);

	// 	var pki = td.columns.indexOf(td.primaryKey);
		var displayCol = sheet.props.displayColumn ?? sheet.idCol.name;
		for(line in sheet.lines) {
			var jLi = new J("<li/>");
			jLi.appendTo(jSubList);
			jLi.append('<span class="table">'+Reflect.field(line, displayCol)+'</span>');
			// jLi.data("uid",td.uid);

			if( line==curLine )
				jLi.addClass("active");
			jLi.click( function(_) {
				selectLine(line);
			});
			ui.modal.ContextMenu.addTo(jLi, [
				{
					label: L._Delete(),
					cb: () -> {},
				},
			]);
		}

	// 	// Make list sortable
		JsTools.makeSortable(jSubList, function(ev) {
			// var jItem = new J(ev.item);
			// var fromIdx = project.defs.getTableIndex( jItem.data("uid") );
			// var toIdx = ev.newIndex>ev.oldIndex
			// 	? jItem.prev().length==0 ? 0 : project.defs.getTableIndex( jItem.prev().data("uid") )
			// 	: jItem.next().length==0 ? project.defs.tables.length-1 : project.defs.getTableIndex( jItem.next().data("uid") );

			// var moved = project.defs.sortTableDef(fromIdx, toIdx);
			// selectTable(moved);
			// editor.ge.emit(TilesetDefSorted);
		});
	}
		
	public function updateForm(){
		if( curLine==null ) {
			jForm.hide();
			return;
		}
		jForm.show();
		jForm.empty();
		for (column in sheet.columns) {
			var name = column.name;
			jForm.append('<dt><label for=editor_$name>$name</label><div class="info">${getInfo(column.type)}<div/</dt><dd></dd>');
			var editor = getEditor(column, curLine);
			editor.attr("id", 'editor_$name');
			editor.appendTo(jForm.find("dd").last());
		}
		JsTools.parseComponents(jForm);
	}

	function inputEditor(column:Column, line:Dynamic) {
		var jInput = new J("<input type='text'>");
		jInput.val(Reflect.field(line, column.name));
		jInput.change(e -> {
			Reflect.setField(line, column.name, jInput.val());
		});
		return jInput;
	}

	function selectEditor(column:Column, line:Dynamic) {
		var jSelect = new J("<select class='advanced'>");
		var options = switch (column.type) {
			case TEnum(values):
				var opts = [];
				for (i => value in values) {
					opts.push({
						label: value,
						value: i
					});
				}
				opts;
			case TRef(sheetName):
				var opts = [];
				var refSheet = sheet.base.getSheet(sheetName);
				var nameCol = refSheet.props.displayColumn ?? refSheet.idCol.name;
				for (line in refSheet.lines) {
					opts.push({
						label: Reflect.field(line, nameCol),
						value: Reflect.field(line, refSheet.idCol.name)
					});
				}
				opts;
			case _:
				throw 'selectEditor cannot be used with ${column.type}';

		}
		if (column.opt) {
			var jOpt = new js.html.Option("-- null --", null, true);
			jSelect.append(jOpt);
		}
		var cur = Reflect.field(line, column.name);
		for (i => option in options) {
			var jOpt = new js.html.Option(option.label, Std.string(i), false, option.value == cur);
			jSelect.append(jOpt);
		}
		jSelect.change(e -> {
			var i = Std.parseInt(jSelect.val());
			var value = i != null ? options[i].value : null;
			Reflect.setField(line, column.name, value);
		});
		return jSelect;
	}

	function dynamicEditor(column:Column, line:Dynamic) {
		var jInput = new J("<input type='text'>");
		jInput.val(Reflect.field(line, column.name));
		jInput.click(e -> {
			new TextEditor(
				Json.stringify(Reflect.field(line, column.name), null, "\t"),
				column.name,
				null,
				LangJson,
				(val) -> {
					jInput.val(val);
					Reflect.setField(line, column.name, sheet.base.parseDynamic(val));
				}
			);
		});
		return jInput;
	}
	function imageEditor(column:Column, line:Dynamic) {
		var value =  Reflect.field(line, column.name);
		var select = JsTools.createTilesetSelect(Editor.ME.project, null, null, false, (uid) -> {
			var td = Editor.ME.project.defs.getTilesetDef(uid);
			var tp = misc.Tabulator.createTilePos(td);
			Reflect.setField(line, column.name, tp);
		});
		if (value == null || (value != null && value.file == null))
			return select;
		var td = Editor.ME.project.defs.getTilesetDefFrom(value.file);
		if (td == null)
			return select;
		var jPicker = JsTools.createTilePicker(td.uid, RectOnly, td.getTileIdsFromRect(misc.Tabulator.tilePosToTilesetRect(value, td)), true, (tileIds) -> {
			var tilesetRect = td.getTileRectFromTileIds(tileIds);
			Reflect.setField(line, column.name, misc.Tabulator.tilesetRectToTilePos(tilesetRect, td));
		});
		jPicker.css("flex", "unset");
		return jPicker;
	}
	function listEditor(column:Column, line:Dynamic) {
		var jContainer = new J("<div>");
		var subSheet = sheet.getSub(column);
		var tabualtor = new misc.Tabulator(jContainer.get(0), subSheet, line);
		return jContainer;
	}
	function checkboxEditor(column:Column, line:Dynamic) {
		var jInput = new J("<input type='checkbox'>");
		jInput.prop("checked", Reflect.field(line, column.name));
		jInput.change(d -> {
			Reflect.setField(line, column.name, jInput.prop("checked"));
		});
		return jInput;
	}

	function getEditor(column:Column, line:Dynamic) {
		switch (column.type) {
			case TString, TId:
				return inputEditor(column, line);
			case TTilePos:
				return imageEditor(column, line);
			case TDynamic:
				return dynamicEditor(column, line);
			case TEnum(_), TRef(_):
				return selectEditor(column, line);
			case TList:
				return listEditor(column, line);
			case TBool:
				return checkboxEditor(column, line);
			case _:
				var todo = new J("<span>");
				todo[0].innerHTML = "TODO";
				return todo;
		}
	}
	function getInfo(type:ColumnType) {
		return switch (type) {
			case TId:
				"This is an unique identifier for the current row. It allows referencing this row from other sheets or columns. Unique identifiers must be valid code identifiers [A-Za-z_][A-Za-z0_9_]*";
			case TString:
				"Any text can be input into this column. CastleDB currently does not allow multiline text";
			case TBool:
				"A checkbox can be used to specify if the column is true or false";
			case TInt:
				"A integer number (which does not have fractional component)";
			case TFloat:
				"Any number";
			case TColor:
				"A numerical value that represents an RGB color";
			case TEnum(_):
				"An exclusive choice between a number of a given custom values. For example: Yes,No,Cancel,Error";
			case TFlags(_):
				"Several optional choices between a list of given custom values. For example: hasHat,hasShirt,hasShoes";
			case TRef(_):
				"A reference to another sheet row, using its unique idenfier";
			case TFile:
				"A relative or absolute path to a target file or image";
			case TImage:
				"An image to be displayed and stored in the database";
			case TTilePos:
				"A sub part of a tileset image";
			case TList:
				"A list of structured values";
			case TDynamic:
				"Any JSON data";
			case _:
				'No info for datatype $type';
		}
	}


}
