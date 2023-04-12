package ui;

import sequelize.Sequelize.ManyModels;
import sequelize.Sequelize.SingleModel;
import haxe.DynamicAccess;
import sequelize.Sequelize.Model;

class TableDefsForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	public var jWrapper : js.jquery.JQuery;
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jWrapper.find("ul.rowList");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWrapper.find("dl.form");

	var table : Model;
	var pk : String;
	var curRow : Null<SingleModel>;


	public function new(table: Model) {
		this.table = table;
		this.pk = table.primaryKeyAttribute;
		this.curRow = null;

		jWrapper = new J('<div class="tableDefsForm"/>');
		jWrapper.html( JsTools.getHtmlTemplate("tableDefsForm"));

		var jButton = jWrapper.find(".createRow");
		jButton.click((x) -> {
			trace("clicked, creating");
			table.create().then((r) -> selectRow(r));
		});

		updateList();
		updateForm();
	}
	public function selectRow(row) {
		curRow = row;
		updateList();
		updateForm();
	}

	public function updateList(){
		// TODO massive performance would be to not query the whole 800 row table on each click :)
		table.findAll().then((data:ManyModels) -> {
			jList.empty();
			var jLi = new J('<li class="subList"/>');
			jLi.appendTo(jList);
			var jSubList = new J('<ul/>');
			jSubList.appendTo(jLi);


			data.forEach((row:SingleModel) -> {
				var jLi = new J("<li/>");
				jLi.appendTo(jSubList);
				jLi.append('<span class="table">'+row.get(this.pk)+'</span>');
				// jLi.data("uid",td.uid);

				if(row.equals(curRow))
					jLi.addClass("active");
				jLi.click( function(_) {
					selectRow(row);
				});
				ui.modal.ContextMenu.addTo(jLi, [
					{
						label: L._Delete(),
						cb: () -> row.destroy(),
					},
				]);
			});
			// Make list sortable
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
		});
		
	}
	public function updateForm(){
		if( curRow==null ) {
			jForm.hide();
			return;
		}
		jForm.show();
		jForm.empty();
		var rows:DynamicAccess<Dynamic> = curRow.get();
		for (key in rows.keys()) {
			jForm.append('<dt><label for=$key>$key</label></dt><dd></dd>');
			var jInput = new J('<input id=$key>');
			jInput.attr("type", "text");
			// if (key == table.primaryKeyAttribute) {
			// 	jInput.attr("disabled", "disabled");
			// }

			Input.linkToDBValue({key: key, row: curRow}, jInput);

			jInput.appendTo(jForm.find("dd").last());
		}
	}
	public function deleteRow(row) {
		//TODO
	}


}
