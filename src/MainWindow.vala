/*
 * MainWindow.vala
 *
 * Copyright 2015 Tony George <teejee2008@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using Gtk;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class MainWindow : Window {
	private Box vbox_main;
	private Box vbox_actions;
	private Box vbox_packages;
	private Box vbox_ppa;
	private Box vbox_theme;
	private Box hbox_filter;

	private Grid grid_backup_buttons;

	private Toolbar toolbar_bottom;
	private ToolButton btn_donate;
	private ToolButton btn_about;

	private Notebook notebook;
	private FileChooserButton fcb_backup;
	private Button btn_open_backup_dir;

	private Button btn_restore_ppa;
	private Button btn_restore_ppa_exec;
	private Button btn_backup_ppa;
	private Button btn_backup_ppa_exec;
	private Button btn_backup_ppa_cancel;
	private Button btn_backup_ppa_select_all;
	private Button btn_backup_ppa_select_none;
	private TreeView tv_ppa;
	private TreeViewColumn col_ppa_status;
	private ScrolledWindow sw_ppa;

	private Button btn_restore_packages;
	private Button btn_restore_packages_exec;
	private Button btn_backup_packages;
	private Button btn_backup_packages_exec;
	private Button btn_backup_packages_cancel;
	private Button btn_backup_packages_select_all;
	private Button btn_backup_packages_select_none;
	private TreeView tv_packages;
	private TreeViewColumn col_pkg_status;
	private TreeModelFilter filter_packages;
	private ScrolledWindow sw_packages;
	private Entry txt_filter;
	private ComboBox cmb_pkg_section;
	private ComboBox cmb_pkg_status;

	private Button btn_restore_cache;
	private Button btn_backup_cache;

	private Button btn_restore_config;
	private Button btn_restore_config_exec;
	private Button btn_reset_config_exec;
	private Button btn_backup_config;
	private Button btn_backup_config_exec;
	private Button btn_backup_config_cancel;
	private Button btn_backup_config_select_all;
	private Button btn_backup_config_select_none;
	private TreeView tv_config;

	private Button btn_restore_theme;
	private Button btn_restore_theme_exec;
	private Button btn_backup_theme;
	private Button btn_backup_theme_exec;
	private Button btn_backup_theme_cancel;
	private Button btn_backup_theme_select_all;
	private Button btn_backup_theme_select_none;
	private TreeView tv_theme;
	private TreeViewColumn col_theme_status;
	private ScrolledWindow sw_theme;

	private Button btn_software_manager;

	private ProgressBar progressbar;
	private Label lbl_status;

	private Gee.HashMap<string, Package> pkg_list_user;
	//private Gee.HashMap<string,Package> pkg_list_all;
	private Gee.HashMap<string, Ppa> ppa_list_user;
	private Gee.ArrayList<Theme> theme_list_user;
	private Gee.ArrayList<AppConfig> config_list_user;

	bool is_running;
	bool is_restore_view = false;

	int def_width = 500;
	int def_height = 450;

	int ex_width = 600;
	int ex_height = 500;

	int icon_size_list = 22;
	int button_width = 85;
	int button_height = 15;

	public MainWindow () {
		title = AppName + " v" + AppVersion;
		window_position = WindowPosition.CENTER;
		//resizable = false;
		destroy.connect (Gtk.main_quit);
		set_default_size (def_width, def_height);
		icon = get_app_icon(16);

		//vboxMain
		vbox_main = new Box (Orientation.VERTICAL, 0);
		add (vbox_main);

		//notebook
		notebook = new Notebook ();
		notebook.show_tabs = false;
		vbox_main.pack_start (notebook, true, true, 0);
		notebook.switch_page.connect(notebook_switch_page);

		//actions ---------------------------------------------

		//lbl_actions
		Label lbl_actions = new Label (_("Actions"));

		//vbox_actions
		vbox_actions = new Box (Gtk.Orientation.VERTICAL, 6);
		vbox_actions.margin = 12;
		notebook.append_page (vbox_actions, lbl_actions);

		init_section_backup_location();

		init_section_backup();

		init_section_tools();

		init_section_toolbar_bottom();

		init_section_status();

		set_bold_font_for_buttons();
	}

	private void init_section_backup_location() {
		// lbl_header_location
		Label lbl_header_location = new Label ("<b>" + _("Backup Directory") + "</b>");
		lbl_header_location.set_use_markup(true);
		lbl_header_location.halign = Align.START;
		lbl_header_location.margin_top = 6;
		lbl_header_location.margin_bottom = 6;
		vbox_actions.pack_start (lbl_header_location, false, true, 0);

		//vbox_backup_dir
		Box vbox_backup_dir = new Box (Gtk.Orientation.HORIZONTAL, 6);
		vbox_actions.pack_start (vbox_backup_dir, false, true, 0);

		//fcb_backup
		fcb_backup = new FileChooserButton (_("Backup Directory"), FileChooserAction.SELECT_FOLDER);
		fcb_backup.margin_left = 6;
		if ((App.backup_dir != null) && dir_exists (App.backup_dir)) {
			fcb_backup.set_filename (App.backup_dir);
		}
		vbox_backup_dir.pack_start (fcb_backup, true, true, 0);

		fcb_backup.selection_changed.connect(() => {
			App.backup_dir = fcb_backup.get_file().get_path() + "/";
		});

		//btn_open_backup_dir
		btn_open_backup_dir = new Gtk.Button.with_label (" " + _("Open") + " ");
		btn_open_backup_dir.set_size_request(80, -1);
		btn_open_backup_dir.set_tooltip_text(_("Open Backup Directory"));
		vbox_backup_dir.pack_start (btn_open_backup_dir, false, true, 0);

		btn_open_backup_dir.clicked.connect(() => {
			if (check_backup_folder()) {
				exo_open_folder(App.backup_dir, false);
			}
		});
	}

	private void init_section_backup() {
		// lbl_header_backup
		Label lbl_header_backup = new Label ("<b>" + _("Backup &amp; Restore") + "</b>");
		lbl_header_backup.set_use_markup(true);
		lbl_header_backup.halign = Align.START;
		lbl_header_backup.margin_top = 6;
		lbl_header_backup.margin_bottom = 6;
		vbox_actions.pack_start (lbl_header_backup, false, true, 0);

		//grid_backup_buttons
		grid_backup_buttons = new Grid();
		grid_backup_buttons.set_column_spacing (6);
		grid_backup_buttons.set_row_spacing (6);
		grid_backup_buttons.margin_left = 6;
		vbox_actions.pack_start (grid_backup_buttons, false, true, 0);

		int row = -1;

		init_section_backup_ppa(++row);
		init_section_backup_ppa_tab();

		init_section_backup_cache(++row);

		init_section_backup_packages(++row);
		init_section_backup_packages_tab();

		init_section_backup_configs(++row);
		init_section_backup_configs_tab();

		init_section_backup_themes(++row);
		init_section_backup_themes_tab();
	}

	private void init_section_backup_ppa(int row) {
		var img = get_shared_icon("x-system-software-sources", "ppa.svg", icon_size_list);
		grid_backup_buttons.attach(img, 0, row, 1, 1);

		//lbl_backup_ppa
		Label lbl_backup_ppa = new Label (" " + _("Software Sources (PPAs)"));
		lbl_backup_ppa.set_tooltip_text(_("Software Sources (Third Party PPAs)"));
		lbl_backup_ppa.set_use_markup(true);
		lbl_backup_ppa.halign = Align.START;
		lbl_backup_ppa.hexpand = true;
		grid_backup_buttons.attach(lbl_backup_ppa, 1, row, 1, 1);

		//btn_backup_ppa
		btn_backup_ppa = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_ppa.set_size_request(button_width, button_height);
		btn_backup_ppa.set_tooltip_text(_("Backup the list of installed PPAs"));
		grid_backup_buttons.attach(btn_backup_ppa, 2, row, 1, 1);

		btn_backup_ppa.clicked.connect(btn_backup_ppa_clicked);

		//btn_restore_ppa
		btn_restore_ppa = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_ppa.set_size_request(button_width, button_height);
		btn_restore_ppa.set_tooltip_text(_("Add missing PPAs"));
		grid_backup_buttons.attach(btn_restore_ppa, 3, row, 1, 1);

		btn_restore_ppa.clicked.connect(btn_restore_ppa_clicked);
	}

	private void init_section_backup_ppa_tab() {
		//lbl_ppa
		Label lbl_ppa = new Label (_("PPA"));

		//vbox_ppa
		vbox_ppa = new Box (Gtk.Orientation.VERTICAL, 6);
		vbox_ppa.margin = 6;
		notebook.append_page (vbox_ppa, lbl_ppa);

		//ppa treeview --------------------------------------------------

		//tv_ppa
		tv_ppa = new TreeView();
		tv_ppa.get_selection().mode = SelectionMode.MULTIPLE;
		tv_ppa.headers_clickable = true;
		tv_ppa.set_rules_hint (true);
		tv_ppa.set_tooltip_column(3);

		//sw_ppa
		sw_ppa = new ScrolledWindow(null, null);
		sw_ppa.set_shadow_type (ShadowType.ETCHED_IN);
		sw_ppa.add (tv_ppa);
		sw_ppa.expand = true;
		vbox_ppa.add(sw_ppa);

		//col_ppa_select ----------------------

		TreeViewColumn col_ppa_select = new TreeViewColumn();
		col_ppa_select.title = "";
		CellRendererToggle cell_ppa_select = new CellRendererToggle ();
		cell_ppa_select.activatable = true;
		col_ppa_select.pack_start (cell_ppa_select, false);
		tv_ppa.append_column(col_ppa_select);

		col_ppa_select.set_cell_data_func (cell_ppa_select, (cell_layout, cell, model, iter) => {
			bool selected;
			Ppa ppa;
			model.get (iter, 0, out selected, 1, out ppa, -1);
			(cell as Gtk.CellRendererToggle).active = selected;
			(cell as Gtk.CellRendererToggle).sensitive = !is_restore_view || !ppa.is_installed;
		});

		cell_ppa_select.toggled.connect((path) => {
			ListStore model = (ListStore)tv_ppa.model;
			bool selected;
			Ppa ppa;
			TreeIter iter;

			model.get_iter_from_string (out iter, path);
			model.get (iter, 0, out selected);
			model.get (iter, 1, out ppa);
			model.set (iter, 0, !selected);
			ppa.is_selected = !selected;
		});

		//col_ppa_status ----------------------

		col_ppa_status = new TreeViewColumn();
		//col_ppa_status.title = _("");
		col_ppa_status.resizable = true;
		tv_ppa.append_column(col_ppa_status);

		CellRendererPixbuf cell_ppa_status = new CellRendererPixbuf ();
		col_ppa_status.pack_start (cell_ppa_status, false);
		col_ppa_status.set_attributes(cell_ppa_status, "pixbuf", 2);

		//col_ppa_name ----------------------

		TreeViewColumn col_ppa_name = new TreeViewColumn();
		col_ppa_name.title = _("PPA");
		col_ppa_name.resizable = true;
		col_ppa_name.min_width = 180;
		tv_ppa.append_column(col_ppa_name);

		CellRendererText cell_ppa_name = new CellRendererText ();
		cell_ppa_name.ellipsize = Pango.EllipsizeMode.END;
		col_ppa_name.pack_start (cell_ppa_name, false);

		col_ppa_name.set_cell_data_func (cell_ppa_name, (cell_layout, cell, model, iter) => {
			Ppa ppa;
			model.get (iter, 1, out ppa, -1);
			(cell as Gtk.CellRendererText).text = ppa.name;
		});

		//col_ppa_desc ----------------------

		TreeViewColumn col_ppa_desc = new TreeViewColumn();
		col_ppa_desc.title = _("Installed Packages");
		col_ppa_desc.resizable = true;
		tv_ppa.append_column(col_ppa_desc);

		CellRendererText cell_ppa_desc = new CellRendererText ();
		cell_ppa_desc.ellipsize = Pango.EllipsizeMode.END;
		col_ppa_desc.pack_start (cell_ppa_desc, false);

		col_ppa_desc.set_cell_data_func (cell_ppa_desc, (cell_layout, cell, model, iter) => {
			Ppa ppa;
			model.get (iter, 1, out ppa, -1);
			(cell as Gtk.CellRendererText).text = ppa.description;
		});

		//hbox_ppa_actions
		Box hbox_ppa_actions = new Box (Orientation.HORIZONTAL, 6);
		vbox_ppa.add (hbox_ppa_actions);

		//btn_backup_ppa_select_all
		btn_backup_ppa_select_all = new Gtk.Button.with_label (" " + _("Select All") + " ");
		hbox_ppa_actions.pack_start (btn_backup_ppa_select_all, true, true, 0);
		btn_backup_ppa_select_all.clicked.connect(() => {
			foreach(Ppa ppa in ppa_list_user.values) {
				if (is_restore_view) {
					if (!ppa.is_installed) {
						ppa.is_selected = true;
					}
					else {
						//no change
					}
				}
				else {
					ppa.is_selected = true;
				}
			}
			tv_ppa_refresh();
		});

		//btn_backup_ppa_select_none
		btn_backup_ppa_select_none = new Gtk.Button.with_label (" " + _("Select None") + " ");
		hbox_ppa_actions.pack_start (btn_backup_ppa_select_none, true, true, 0);
		btn_backup_ppa_select_none.clicked.connect(() => {
			foreach(Ppa ppa in ppa_list_user.values) {
				if (is_restore_view) {
					if (!ppa.is_installed) {
						ppa.is_selected = false;
					}
					else {
						//no change
					}
				}
				else {
					ppa.is_selected = false;
				}
			}
			tv_ppa_refresh();
		});

		//btn_backup_ppa_exec
		btn_backup_ppa_exec = new Gtk.Button.with_label (" <b>" + _("Backup") + "</b> ");
		btn_backup_ppa_exec.no_show_all = true;
		hbox_ppa_actions.pack_start (btn_backup_ppa_exec, true, true, 0);
		btn_backup_ppa_exec.clicked.connect(btn_backup_ppa_exec_clicked);

		//btn_restore_ppa_exec
		btn_restore_ppa_exec = new Gtk.Button.with_label (" <b>" + _("Restore") + "</b> ");
		btn_restore_ppa_exec.no_show_all = true;
		hbox_ppa_actions.pack_start (btn_restore_ppa_exec, true, true, 0);
		btn_restore_ppa_exec.clicked.connect(btn_restore_ppa_exec_clicked);

		//btn_backup_ppa_cancel
		btn_backup_ppa_cancel = new Gtk.Button.with_label (" " + _("Cancel") + " ");
		hbox_ppa_actions.pack_start (btn_backup_ppa_cancel, true, true, 0);
		btn_backup_ppa_cancel.clicked.connect(() => {
			show_home_page();
		});
	}

	private void init_section_backup_cache(int row) {
		var img = get_shared_icon("download", "cache.svg", icon_size_list);
		grid_backup_buttons.attach(img, 0, row, 1, 1);

		//lbl_backup_cache
		Label lbl_backup_cache = new Label (" " + _("Downloaded Packages (APT Cache)"));
		lbl_backup_cache.set_tooltip_text(_("Downloaded Packages (APT Cache)"));
		lbl_backup_cache.set_use_markup(true);
		lbl_backup_cache.halign = Align.START;
		lbl_backup_cache.hexpand = true;
		grid_backup_buttons.attach(lbl_backup_cache, 1, row, 1, 1);

		//btn_backup_cache
		btn_backup_cache = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_cache.set_size_request(button_width, button_height);
		btn_backup_cache.set_tooltip_text(_("Backup downloaded packages from APT cache"));
		btn_backup_cache.clicked.connect(btn_backup_cache_clicked);
		grid_backup_buttons.attach(btn_backup_cache, 2, row, 1, 1);

		//btn_restore_cache
		btn_restore_cache = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_cache.set_size_request(button_width, button_height);
		btn_restore_cache.set_tooltip_text(_("Restore downloaded packages to APT cache"));
		btn_restore_cache.clicked.connect(btn_restore_cache_clicked);
		grid_backup_buttons.attach(btn_restore_cache, 3, row, 1, 1);
	}

	private void init_section_backup_packages(int row) {
		var img = get_shared_icon("gnome-package", "package.svg", icon_size_list);
		grid_backup_buttons.attach(img, 0, row, 1, 1);

		//lbl_backup_packages
		Label lbl_backup_packages = new Label (" " + _("Software Selections"));
		lbl_backup_packages.set_tooltip_text(_("Software Selections (Installed Packages)"));
		lbl_backup_packages.set_use_markup(true);
		lbl_backup_packages.halign = Align.START;
		lbl_backup_packages.hexpand = true;
		grid_backup_buttons.attach(lbl_backup_packages, 1, row, 1, 1);

		//btn_backup_packages
		btn_backup_packages = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_packages.set_size_request(button_width, button_height);
		btn_backup_packages.set_tooltip_text(_("Backup the list of installed packages"));
		btn_backup_packages.vexpand = false;
		grid_backup_buttons.attach(btn_backup_packages, 2, row, 1, 1);

		btn_backup_packages.clicked.connect(btn_backup_packages_clicked);

		//btn_restore_packages
		btn_restore_packages = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_packages.set_size_request(button_width, button_height);
		btn_restore_packages.set_tooltip_text(_("Install missing packages"));
		grid_backup_buttons.attach(btn_restore_packages, 3, row, 1, 1);

		btn_restore_packages.clicked.connect(btn_restore_packages_clicked);
	}

	private void init_section_backup_packages_tab() {
		//lbl_packages
		Label lbl_packages = new Label (_("Packages"));

		//vbox_packages
		vbox_packages = new Box (Gtk.Orientation.VERTICAL, 6);
		vbox_packages.margin = 6;
		notebook.append_page (vbox_packages, lbl_packages);

		init_section_backup_packages_tab_filters();


		//tooltips -------------------------------------------------------------

		// TODO: Fix messages

		string tt = "";
		string pkg_note = "<b>Note:</b> Since default packages are already included with your Linux distribution\nand dependency packages are installed automatically,\nyou only need to backup <b>top-level</b> and <b>extra</b> packages";

		tt = _("<b>All</b> - All default and extra packages") + "\n" + _("<b>Default</b> - Default packages (installed with distribution)") + "\n" + _("<b>Extra</b> - Extra packages (installed by user)");
		//cmb_pkg_type.set_tooltip_markup(tt + "\n\n" + pkg_note);

		tt = _("<b>All</b> - All top-level packages and dependencies") + "\n" + _("<b>Top-Level</b> - Top-level packages (not required by other packages)") + "\n" + _("<b>Dependencies</b> - Dependency packages (required by other packages)");
		//cmb_pkg_level.set_tooltip_markup(tt + "\n\n" + pkg_note);

		pkg_note = "<b>Note:</b> For missing packages, check if the required PPAs have been added to the system";
		tt = _("<b>All</b> - All packages in backup list") + "\n" + _("<b>Installed</b> - Installed packages") + "\n" + _("<b>Available</b> - Packages which are available but not installed") + "\n" + _("<b>Missing</b> - Packages which are not installed and not available");
		//cmb_pkg_status.set_tooltip_markup(tt + "\n\n" + pkg_note);

		tt = _("Search package name and description");
		txt_filter.set_tooltip_markup(tt);

		init_section_backup_packages_tab_treeview();

		init_section_backup_packages_tab_actions();
	}

	private void init_section_backup_packages_tab_filters() {
		//hbox_filter
		hbox_filter = new Box (Orientation.HORIZONTAL, 6);
		hbox_filter.margin_left = 3;
		hbox_filter.margin_right = 3;
		vbox_packages.pack_start (hbox_filter, false, true, 0);

		//filter
		Label lbl_filter = new Label(_("Filter"));
		hbox_filter.add (lbl_filter);

		txt_filter = new Entry();
		txt_filter.hexpand = true;
		hbox_filter.add (txt_filter);

		//cmb_pkg_status
		cmb_pkg_status = new ComboBox();
		cmb_pkg_status.set_tooltip_text(_("Package State\n\nInstalled\tPackages which are in Installed state\nNot-Installed\t\tPackages which are not in Installed state"));
		hbox_filter.add (cmb_pkg_status);

		CellRendererText cell_pkg_restore_status = new CellRendererText();
		cmb_pkg_status.pack_start(cell_pkg_restore_status, false );
		cmb_pkg_status.set_cell_data_func (cell_pkg_restore_status, (cell_pkg_restore_status, cell, model, iter) => {
			string status;
			model.get (iter, 0, out status, -1);
			(cell as Gtk.CellRendererText).text = status;
		});

		//cmb_pkg_section
		cmb_pkg_section = new ComboBox();
		cmb_pkg_section.set_tooltip_text(_("Category"));
		hbox_filter.add (cmb_pkg_section);

		CellRendererText cell_pkg_section = new CellRendererText();
		cmb_pkg_section.pack_start(cell_pkg_section, false );
		cmb_pkg_section.set_cell_data_func (cell_pkg_section, (cell_pkg_section, cell, model, iter) => {
			string section;
			model.get (iter, 0, out section, -1);
			(cell as Gtk.CellRendererText).text = section;
		});

		//filter events -------------

		txt_filter.changed.connect(() => {
			filter_packages.refilter();
		});
	}

	private void init_section_backup_packages_tab_treeview() {
		//tv_packages
		tv_packages = new TreeView();
		tv_packages.get_selection().mode = SelectionMode.MULTIPLE;
		tv_packages.headers_clickable = true;
		tv_packages.set_rules_hint (true);
		tv_packages.set_tooltip_column(3);

		//sw_packages
		sw_packages = new ScrolledWindow(null, null);
		sw_packages.set_shadow_type (ShadowType.ETCHED_IN);
		sw_packages.add (tv_packages);
		sw_packages.expand = true;
		vbox_packages.add(sw_packages);

		//col_pkg_select ----------------------

		TreeViewColumn col_pkg_select = new TreeViewColumn();
		tv_packages.append_column(col_pkg_select);

		CellRendererToggle cell_pkg_select = new CellRendererToggle ();
		cell_pkg_select.activatable = true;
		col_pkg_select.pack_start (cell_pkg_select, false);

		col_pkg_select.set_cell_data_func (cell_pkg_select, (cell_layout, cell, model, iter) => {
			bool selected;
			Package pkg;
			model.get (iter, 0, out selected, 1, out pkg, -1);
			(cell as Gtk.CellRendererToggle).active = selected;
		});

		cell_pkg_select.toggled.connect((path) => {
			TreeModel model = filter_packages;
			ListStore store = (ListStore) filter_packages.child_model;
			bool selected;
			Package pkg;

			TreeIter iter, child_iter;
			model.get_iter_from_string (out iter, path);
			model.get (iter, 0, out selected, 1, out pkg, -1);

			pkg.is_selected = !selected;

			filter_packages.convert_iter_to_child_iter(out child_iter, iter);
			store.set(child_iter, 0, pkg.is_selected, -1);
		});

		//col_pkg_status ----------------------

		col_pkg_status = new TreeViewColumn();
		//col_pkg_status.title = _("");
		col_pkg_status.resizable = true;
		tv_packages.append_column(col_pkg_status);

		CellRendererPixbuf cell_pkg_status = new CellRendererPixbuf ();
		col_pkg_status.pack_start (cell_pkg_status, false);
		col_pkg_status.set_attributes(cell_pkg_status, "pixbuf", 2);

		//col_pkg_name ----------------------

		TreeViewColumn col_pkg_name = new TreeViewColumn();
		col_pkg_name.title = _("Package");
		col_pkg_name.resizable = true;
		col_pkg_name.min_width = 180;
		tv_packages.append_column(col_pkg_name);

		CellRendererText cell_pkg_name = new CellRendererText ();
		cell_pkg_name.ellipsize = Pango.EllipsizeMode.END;
		col_pkg_name.pack_start (cell_pkg_name, false);

		col_pkg_name.set_cell_data_func (cell_pkg_name, (cell_layout, cell, model, iter) => {
			Package pkg;
			model.get (iter, 1, out pkg, -1);
			(cell as Gtk.CellRendererText).text = pkg.name;
		});

		//col_pkg_installed ----------------------

		TreeViewColumn col_pkg_installed = new TreeViewColumn();
		col_pkg_installed.title = _("Installed");
		col_pkg_installed.resizable = true;
		col_pkg_installed.min_width = 120;
		tv_packages.append_column(col_pkg_installed);

		CellRendererText cell_pkg_installed = new CellRendererText ();
		cell_pkg_installed.ellipsize = Pango.EllipsizeMode.END;
		col_pkg_installed.pack_start (cell_pkg_installed, false);

		col_pkg_installed.set_cell_data_func (cell_pkg_installed, (cell_layout, cell, model, iter) => {
			Package pkg;
			model.get (iter, 1, out pkg, -1);
			(cell as Gtk.CellRendererText).text = pkg.version_installed;
		});

		//col_pkg_latest ----------------------

		TreeViewColumn col_pkg_latest = new TreeViewColumn();
		col_pkg_latest.title = _("Latest");
		col_pkg_latest.resizable = true;
		col_pkg_latest.min_width = 120;
		tv_packages.append_column(col_pkg_latest);

		CellRendererText cell_pkg_latest = new CellRendererText ();
		cell_pkg_latest.ellipsize = Pango.EllipsizeMode.END;
		col_pkg_latest.pack_start (cell_pkg_latest, false);

		col_pkg_latest.set_cell_data_func (cell_pkg_latest, (cell_layout, cell, model, iter) => {
			Package pkg;
			model.get (iter, 1, out pkg, -1);
			(cell as Gtk.CellRendererText).text = pkg.version_available;
		});

		//col_pkg_desc ----------------------

		TreeViewColumn col_pkg_desc = new TreeViewColumn();
		col_pkg_desc.title = _("Description");
		col_pkg_desc.resizable = true;
		tv_packages.append_column(col_pkg_desc);

		CellRendererText cell_pkg_desc = new CellRendererText ();
		cell_pkg_desc.ellipsize = Pango.EllipsizeMode.END;
		col_pkg_desc.pack_start (cell_pkg_desc, false);

		col_pkg_desc.set_cell_data_func (cell_pkg_desc, (cell_layout, cell, model, iter) => {
			Package pkg;
			model.get (iter, 1, out pkg, -1);
			(cell as Gtk.CellRendererText).text = pkg.description;
		});
	}

	private void init_section_backup_packages_tab_actions() {
		//hbox_pkg_actions
		Box hbox_pkg_actions = new Box (Orientation.HORIZONTAL, 6);
		vbox_packages.add (hbox_pkg_actions);

		//btn_backup_packages_select_all
		btn_backup_packages_select_all = new Gtk.Button.with_label (" " + _("Select All") + " ");
		hbox_pkg_actions.pack_start (btn_backup_packages_select_all, true, true, 0);
		btn_backup_packages_select_all.clicked.connect(() => {
			foreach(Package pkg in pkg_list_user.values) {
				if (is_restore_view) {
					if (pkg.is_available && !pkg.is_installed) {
						pkg.is_selected = true;
					}
					else {
						//no change
					}
				}
				else {
					pkg.is_selected = true;
				}
			}
			tv_packages_refresh();
		});

		//btn_backup_packages_select_none
		btn_backup_packages_select_none = new Gtk.Button.with_label (" " + _("Select None") + " ");
		hbox_pkg_actions.pack_start (btn_backup_packages_select_none, true, true, 0);
		btn_backup_packages_select_none.clicked.connect(() => {
			foreach(Package pkg in pkg_list_user.values) {
				if (is_restore_view) {
					if (pkg.is_available && !pkg.is_installed) {
						pkg.is_selected = false;
					}
					else {
						//no change
					}
				}
				else {
					pkg.is_selected = false;
				}
			}
			tv_packages_refresh();
		});

		//btn_backup_packages_exec
		btn_backup_packages_exec = new Gtk.Button.with_label (" <b>" + _("Backup") + "</b> ");
		btn_backup_packages_exec.no_show_all = true;
		hbox_pkg_actions.pack_start (btn_backup_packages_exec, true, true, 0);
		btn_backup_packages_exec.clicked.connect(btn_backup_packages_exec_clicked);

		//btn_restore_packages_exec
		btn_restore_packages_exec = new Gtk.Button.with_label (" <b>" + _("Restore") + "</b> ");
		btn_restore_packages_exec.no_show_all = true;
		hbox_pkg_actions.pack_start (btn_restore_packages_exec, true, true, 0);
		btn_restore_packages_exec.clicked.connect(btn_restore_packages_exec_clicked);

		//btn_backup_packages_cancel
		btn_backup_packages_cancel = new Gtk.Button.with_label (" " + _("Cancel") + " ");
		hbox_pkg_actions.pack_start (btn_backup_packages_cancel, true, true, 0);
		btn_backup_packages_cancel.clicked.connect(() => {
			show_home_page();
		});
	}

	private void init_section_backup_configs(int row) {
		var img = get_shared_icon("gnome-settings", "config.svg", icon_size_list);
		grid_backup_buttons.attach(img, 0, row, 1, 1);

		//lbl_backup_config
		Label lbl_backup_config = new Label (" " + _("Application Settings"));
		lbl_backup_config.set_tooltip_text(_("Application Settings"));
		lbl_backup_config.set_use_markup(true);
		lbl_backup_config.halign = Align.START;
		lbl_backup_config.hexpand = true;
		grid_backup_buttons.attach(lbl_backup_config, 1, row, 1, 1);

		//btn_backup_config
		btn_backup_config = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_config.set_size_request(button_width, button_height);
		btn_backup_config.set_tooltip_text(_("Backup application settings"));
		grid_backup_buttons.attach(btn_backup_config, 2, row, 1, 1);

		btn_backup_config.clicked.connect(btn_backup_config_clicked);

		//btn_restore_config
		btn_restore_config = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_config.set_size_request(button_width, button_height);
		btn_restore_config.set_tooltip_text(_("Restore application settings"));
		grid_backup_buttons.attach(btn_restore_config, 3, row, 1, 1);

		btn_restore_config.clicked.connect(btn_restore_config_clicked);
	}

	private void init_section_backup_configs_tab() {
		//lbl_config
		Label lbl_config = new Label (_("Config"));

		//vbox_config
		Box vbox_config = new Box (Gtk.Orientation.VERTICAL, 6);
		vbox_config.margin = 6;
		notebook.append_page (vbox_config, lbl_config);

		//config treeview --------------------------------------------------

		//tv_config
		tv_config = new TreeView();
		tv_config.get_selection().mode = SelectionMode.MULTIPLE;
		tv_config.headers_clickable = true;
		tv_config.set_rules_hint (true);
		//tv_config.set_tooltip_column(3);

		//sw_config
		ScrolledWindow sw_config = new ScrolledWindow(null, null);
		sw_config.set_shadow_type (ShadowType.ETCHED_IN);
		sw_config.add (tv_config);
		sw_config.expand = true;
		vbox_config.add(sw_config);

		//col_config_select ----------------------

		TreeViewColumn col_config_select = new TreeViewColumn();
		col_config_select.title = "";
		CellRendererToggle cell_config_select = new CellRendererToggle ();
		cell_config_select.activatable = true;
		col_config_select.pack_start (cell_config_select, false);
		tv_config.append_column(col_config_select);

		col_config_select.set_cell_data_func (cell_config_select, (cell_layout, cell, model, iter) => {
			bool selected;
			AppConfig config;
			model.get (iter, 0, out selected, 1, out config, -1);
			(cell as Gtk.CellRendererToggle).active = selected;
		});

		cell_config_select.toggled.connect((path) => {
			ListStore model = (ListStore)tv_config.model;
			bool selected;
			AppConfig config;
			TreeIter iter;

			model.get_iter_from_string (out iter, path);
			model.get (iter, 0, out selected);
			model.get (iter, 1, out config);
			model.set (iter, 0, !selected);
			config.is_selected = !selected;
		});

		//col_config_name ----------------------

		TreeViewColumn col_config_name = new TreeViewColumn();
		col_config_name.title = _("Path");
		col_config_name.resizable = true;
		col_config_name.min_width = 180;
		tv_config.append_column(col_config_name);

		CellRendererText cell_config_name = new CellRendererText ();
		cell_config_name.ellipsize = Pango.EllipsizeMode.END;
		col_config_name.pack_start (cell_config_name, false);

		col_config_name.set_cell_data_func (cell_config_name, (cell_layout, cell, model, iter) => {
			AppConfig config;
			model.get (iter, 1, out config, -1);
			(cell as Gtk.CellRendererText).text = config.name;
		});

		TreeViewColumn col_config_size = new TreeViewColumn();
		col_config_size.title = _("Size");
		col_config_size.resizable = true;
		tv_config.append_column(col_config_size);

		CellRendererText cell_config_size = new CellRendererText ();
		cell_config_size.xalign = (float) 1.0;
		col_config_size.pack_start (cell_config_size, false);

		col_config_size.set_cell_data_func (cell_config_size, (cell_layout, cell, model, iter) => {
			AppConfig config;
			model.get (iter, 1, out config, -1);
			(cell as Gtk.CellRendererText).text = config.size;
			if (config.size.contains("M") || config.size.contains("G")) {
				(cell as Gtk.CellRendererText).foreground = "red";
			}
			else {
				(cell as Gtk.CellRendererText).foreground = null;
			}
		});

		//col_config_desc ----------------------

		TreeViewColumn col_config_desc = new TreeViewColumn();
		col_config_desc.title = _("Description");
		col_config_desc.resizable = true;
		tv_config.append_column(col_config_desc);

		CellRendererText cell_config_desc = new CellRendererText ();
		cell_config_desc.ellipsize = Pango.EllipsizeMode.END;
		col_config_desc.pack_start (cell_config_desc, false);

		col_config_desc.set_cell_data_func (cell_config_desc, (cell_layout, cell, model, iter) => {
			AppConfig config;
			model.get (iter, 1, out config, -1);
			(cell as Gtk.CellRendererText).text = config.description;
		});

		//hbox_config_actions
		Box hbox_config_actions = new Box (Orientation.HORIZONTAL, 6);
		vbox_config.add (hbox_config_actions);

		//btn_backup_config_select_all
		btn_backup_config_select_all = new Gtk.Button.with_label (" " + _("Select All") + " ");
		hbox_config_actions.pack_start (btn_backup_config_select_all, true, true, 0);
		btn_backup_config_select_all.clicked.connect(() => {
			foreach(AppConfig config in config_list_user) {
				config.is_selected = true;
			}
			tv_config_refresh();
		});

		//btn_backup_config_select_none
		btn_backup_config_select_none = new Gtk.Button.with_label (" " + _("Select None") + " ");
		hbox_config_actions.pack_start (btn_backup_config_select_none, true, true, 0);
		btn_backup_config_select_none.clicked.connect(() => {
			foreach(AppConfig config in config_list_user) {
				config.is_selected = false;
			}
			tv_config_refresh();
		});

		//btn_backup_config_exec
		btn_backup_config_exec = new Gtk.Button.with_label (" <b>" + _("Backup") + "</b> ");
		btn_backup_config_exec.no_show_all = true;
		hbox_config_actions.pack_start (btn_backup_config_exec, true, true, 0);
		btn_backup_config_exec.clicked.connect(btn_backup_config_exec_clicked);

		//btn_restore_config_exec
		btn_restore_config_exec = new Gtk.Button.with_label (" <b>" + _("Restore") + "</b> ");
		btn_restore_config_exec.no_show_all = true;
		btn_restore_config_exec.set_tooltip_text(_("Restore the settings for an application (Eg: Chromium Browser) by replacing the settings directory (~/.config/chromium) with files from backup. Use the 'Reset' button to delete the restored files in case of issues."));
		hbox_config_actions.pack_start (btn_restore_config_exec, true, true, 0);
		btn_restore_config_exec.clicked.connect(btn_restore_config_exec_clicked);

		//btn_reset_config_exec
		btn_reset_config_exec = new Gtk.Button.with_label (" " + _("Reset") + " ");
		btn_reset_config_exec.no_show_all = true;
		btn_reset_config_exec.set_tooltip_text(_("Reset the settings for an application (Eg: Chromium Browser) by deleting the settings directory (~/.config/chromium). The directory will be created automatically with default configuration files on the next run of the application."));
		hbox_config_actions.pack_start (btn_reset_config_exec, true, true, 0);
		btn_reset_config_exec.clicked.connect(btn_reset_config_exec_clicked);

		//btn_backup_config_cancel
		btn_backup_config_cancel = new Gtk.Button.with_label (" " + _("Cancel") + " ");
		hbox_config_actions.pack_start (btn_backup_config_cancel, true, true, 0);
		btn_backup_config_cancel.clicked.connect(() => {
			show_home_page();
		});
	}

	private void init_section_backup_themes(int row) {
		var img = get_shared_icon("preferences-theme", "theme.svg", icon_size_list);
		grid_backup_buttons.attach(img, 0, row, 1, 1);

		//lbl_backup_theme
		Label lbl_backup_theme = new Label (" " + _("Themes and Icons"));
		lbl_backup_theme.set_tooltip_text(_("Themes and Icons"));
		lbl_backup_theme.set_use_markup(true);
		lbl_backup_theme.halign = Align.START;
		lbl_backup_theme.hexpand = true;
		grid_backup_buttons.attach(lbl_backup_theme, 1, row, 1, 1);

		//btn_backup_theme
		btn_backup_theme = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_theme.set_size_request(button_width, button_height);
		btn_backup_theme.set_tooltip_text(_("Backup themes and icons"));
		grid_backup_buttons.attach(btn_backup_theme, 2, row, 1, 1);

		btn_backup_theme.clicked.connect(btn_backup_theme_clicked);

		//btn_restore_theme
		btn_restore_theme = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_theme.set_size_request(button_width, button_height);
		btn_restore_theme.set_tooltip_text(_("Restore themes and icons"));
		grid_backup_buttons.attach(btn_restore_theme, 3, row, 1, 1);

		btn_restore_theme.clicked.connect(btn_restore_theme_clicked);
	}

	private void init_section_backup_themes_tab() {
		//lbl_theme
		Label lbl_theme = new Label (_("Theme"));

		//vbox_theme
		vbox_theme = new Box (Gtk.Orientation.VERTICAL, 6);
		vbox_theme.margin = 6;
		notebook.append_page (vbox_theme, lbl_theme);

		//theme treeview --------------------------------------------------

		//tv_theme
		tv_theme = new TreeView();
		tv_theme.get_selection().mode = SelectionMode.MULTIPLE;
		tv_theme.headers_clickable = true;
		tv_theme.set_rules_hint (true);
		tv_theme.set_tooltip_column(3);

		//sw_theme
		sw_theme = new ScrolledWindow(null, null);
		sw_theme.set_shadow_type (ShadowType.ETCHED_IN);
		sw_theme.add (tv_theme);
		sw_theme.expand = true;
		vbox_theme.add(sw_theme);

		//col_theme_select ----------------------

		TreeViewColumn col_theme_select = new TreeViewColumn();
		col_theme_select.title = "";
		CellRendererToggle cell_theme_select = new CellRendererToggle ();
		cell_theme_select.activatable = true;
		col_theme_select.pack_start (cell_theme_select, false);
		tv_theme.append_column(col_theme_select);

		col_theme_select.set_cell_data_func (cell_theme_select, (cell_layout, cell, model, iter) => {
			bool selected;
			Theme theme;
			model.get (iter, 0, out selected, 1, out theme, -1);
			(cell as Gtk.CellRendererToggle).active = selected;
			(cell as Gtk.CellRendererToggle).sensitive = !is_restore_view || !theme.is_installed;
		});

		cell_theme_select.toggled.connect((path) => {
			ListStore model = (ListStore)tv_theme.model;
			bool selected;
			Theme theme;
			TreeIter iter;

			model.get_iter_from_string (out iter, path);
			model.get (iter, 0, out selected);
			model.get (iter, 1, out theme);
			model.set (iter, 0, !selected);
			theme.is_selected = !selected;
		});

		//col_theme_status ----------------------

		col_theme_status = new TreeViewColumn();
		//col_theme_status.title = _("");
		col_theme_status.resizable = true;
		tv_theme.append_column(col_theme_status);

		CellRendererPixbuf cell_theme_status = new CellRendererPixbuf ();
		col_theme_status.pack_start (cell_theme_status, false);
		col_theme_status.set_attributes(cell_theme_status, "pixbuf", 2);

		//col_theme_name ----------------------

		TreeViewColumn col_theme_name = new TreeViewColumn();
		col_theme_name.title = _("Theme");
		col_theme_name.resizable = true;
		col_theme_name.min_width = 180;
		tv_theme.append_column(col_theme_name);

		CellRendererText cell_theme_name = new CellRendererText ();
		cell_theme_name.ellipsize = Pango.EllipsizeMode.END;
		col_theme_name.pack_start (cell_theme_name, false);

		col_theme_name.set_cell_data_func (cell_theme_name, (cell_layout, cell, model, iter) => {
			Theme theme;
			model.get (iter, 1, out theme, -1);
			(cell as Gtk.CellRendererText).text = theme.name;
		});

		//col_theme_desc ----------------------

		TreeViewColumn col_theme_desc = new TreeViewColumn();
		col_theme_desc.title = _("Path");
		col_theme_desc.resizable = true;
		tv_theme.append_column(col_theme_desc);

		CellRendererText cell_theme_desc = new CellRendererText ();
		cell_theme_desc.ellipsize = Pango.EllipsizeMode.END;
		col_theme_desc.pack_start (cell_theme_desc, false);

		col_theme_desc.set_cell_data_func (cell_theme_desc, (cell_layout, cell, model, iter) => {
			Theme theme;
			model.get (iter, 1, out theme, -1);
			(cell as Gtk.CellRendererText).text = (theme.zip_file_path.length > 0) ? theme.zip_file_path : theme.system_path;
		});

		//hbox_theme_actions
		Box hbox_theme_actions = new Box (Orientation.HORIZONTAL, 6);
		vbox_theme.add (hbox_theme_actions);

		//btn_backup_theme_select_all
		btn_backup_theme_select_all = new Gtk.Button.with_label (" " + _("Select All") + " ");
		hbox_theme_actions.pack_start (btn_backup_theme_select_all, true, true, 0);
		btn_backup_theme_select_all.clicked.connect(() => {
			foreach(Theme theme in theme_list_user) {
				if (is_restore_view) {
					if (!theme.is_installed) {
						theme.is_selected = true;
					}
					else {
						//no change
					}
				}
				else {
					theme.is_selected = true;
				}
			}
			tv_theme_refresh();
		});

		//btn_backup_theme_select_none
		btn_backup_theme_select_none = new Gtk.Button.with_label (" " + _("Select None") + " ");
		hbox_theme_actions.pack_start (btn_backup_theme_select_none, true, true, 0);
		btn_backup_theme_select_none.clicked.connect(() => {
			foreach(Theme theme in theme_list_user) {
				if (is_restore_view) {
					if (!theme.is_installed) {
						theme.is_selected = false;
					}
					else {
						//no change
					}
				}
				else {
					theme.is_selected = false;
				}
			}
			tv_theme_refresh();
		});

		//btn_backup_theme_exec
		btn_backup_theme_exec = new Gtk.Button.with_label (" <b>" + _("Backup") + "</b> ");
		btn_backup_theme_exec.no_show_all = true;
		hbox_theme_actions.pack_start (btn_backup_theme_exec, true, true, 0);
		btn_backup_theme_exec.clicked.connect(btn_backup_theme_exec_clicked);

		//btn_restore_theme_exec
		btn_restore_theme_exec = new Gtk.Button.with_label (" <b>" + _("Restore") + "</b> ");
		btn_restore_theme_exec.no_show_all = true;
		hbox_theme_actions.pack_start (btn_restore_theme_exec, true, true, 0);
		btn_restore_theme_exec.clicked.connect(btn_restore_theme_exec_clicked);

		//btn_backup_theme_cancel
		btn_backup_theme_cancel = new Gtk.Button.with_label (" " + _("Cancel") + " ");
		hbox_theme_actions.pack_start (btn_backup_theme_cancel, true, true, 0);
		btn_backup_theme_cancel.clicked.connect(() => {
			show_home_page();
		});
	}

	private void init_section_tools() {
		// lbl_header_tools
		Label lbl_header_tools = new Label ("<b>" + _("Tools &amp; Tweaks") + "</b>");
		lbl_header_tools.set_use_markup(true);
		lbl_header_tools.halign = Align.START;
		lbl_header_tools.margin_top = 6;
		lbl_header_tools.margin_bottom = 6;
		vbox_actions.pack_start (lbl_header_tools, false, true, 0);

		//grid_backup_tools
		Grid grid_backup_tools = new Grid();
		grid_backup_tools.set_column_spacing (6);
		grid_backup_tools.set_row_spacing (6);
		grid_backup_tools.margin_left = 6;
		vbox_actions.pack_start (grid_backup_tools, false, true, 0);

		int row = 1;

		//btn_software_manager
		btn_software_manager = new Gtk.Button.with_label (" " + _("Software Manager") + " ");
		btn_software_manager.set_size_request(button_width, button_height);
		btn_software_manager.set_tooltip_text(_("Add &amp; Remove Software Packages"));
		grid_backup_tools.attach(btn_software_manager, 0, row, 1, 1);

		btn_software_manager.clicked.connect(() => {
			var win = new PackageManagerWindow.with_parent(this);
			win.title = "Aptik Package Manager" + " v" + AppVersion;
			win.show_all();
			//dialog.destroy();
		});

		//btn_battery_monitor
		var btn_battery_monitor = new Gtk.Button.with_label (" " + _("Battery Monitor") + " ");
		btn_battery_monitor.set_size_request(button_width, button_height);
		btn_battery_monitor.set_tooltip_text(_("View battery statistics"));
		grid_backup_tools.attach(btn_battery_monitor, 1, row, 1, 1);

		string path = get_cmd_path("aptik-bmon-gtk");
		btn_battery_monitor.sensitive = (path != null) && (path.length > 0);

		btn_battery_monitor.clicked.connect(() => {
			Posix.system("aptik-bmon-gtk");
		});
		/*
				//btn_mount_manager
			 	var btn_mount_manager = new Gtk.Button.with_label (" " + _("Mount Manager") + " ");
				btn_mount_manager.set_size_request(button_width,button_height);
				btn_mount_manager.set_tooltip_text(_("Add &amp; Remove Software Packages"));
				grid_backup_tools.attach(btn_mount_manager,1,row,1,1);


				//btn_ssd_tweaks
			 	var btn_ssd_tweaks = new Gtk.Button.with_label (" " + _("SSD Tweaks") + " ");
				btn_ssd_tweaks.set_size_request(button_width,button_height);
				btn_ssd_tweaks.set_tooltip_text(_("Add &amp; Remove Software Packages"));
				grid_backup_tools.attach(btn_ssd_tweaks,2,row,1,1);

				//btn_icon_explorer
			 	var btn_icon_explorer = new Gtk.Button.with_label (" " + _("Icon Explorer") + " ");
				btn_icon_explorer.set_size_request(button_width,button_height);
				btn_icon_explorer.set_tooltip_text(_("Add &amp; Remove Software Packages"));
				grid_backup_tools.attach(btn_icon_explorer,0,++row,1,1);

				//btn_brightness_fix
				var btn_brightness_fix = new Gtk.Button.with_label (" " + _("Brightness Fix") + " ");
				btn_brightness_fix.set_size_request(button_width,button_height);
				btn_brightness_fix.set_tooltip_text(_("Fix for maintaining display brightness level after reboot"));
				grid_backup_tools.attach(btn_brightness_fix,0,++row,1,1);
				*/
	}

	private void init_section_status() {
		//lbl_status
		lbl_status = new Label ("");
		lbl_status.halign = Align.START;
		lbl_status.max_width_chars = 50;
		lbl_status.ellipsize = Pango.EllipsizeMode.END;
		lbl_status.no_show_all = true;
		lbl_status.visible = false;
		lbl_status.margin_bottom = 3;
		lbl_status.margin_left = 3;
		lbl_status.margin_right = 3;
		vbox_main.pack_start (lbl_status, false, true, 0);

		//progressbar
		progressbar = new ProgressBar();
		progressbar.no_show_all = true;
		progressbar.margin_bottom = 3;
		progressbar.margin_left = 3;
		progressbar.margin_right = 3;
		progressbar.set_size_request(-1, 25);
		//progressbar.pulse_step = 0.2;
		vbox_main.pack_start (progressbar, false, true, 0);
	}

	private void init_section_toolbar_bottom() {
		//toolbar_bottom
		toolbar_bottom = new Gtk.Toolbar();
		toolbar_bottom.toolbar_style = ToolbarStyle.BOTH;
		vbox_main.add(toolbar_bottom);

		//separator
		var separator = new Gtk.SeparatorToolItem();
		separator.set_draw (false);
		separator.set_expand (true);
		toolbar_bottom.add(separator);

		//btn_donate
		btn_donate = new Gtk.ToolButton.from_stock ("gtk-missing-image");
		btn_donate.label = _("Donate");
		btn_donate.set_tooltip_text (_("Donate"));
		btn_donate.icon_widget = get_shared_icon("donate", "donate.svg", 32);
		toolbar_bottom.add(btn_donate);

		btn_donate.clicked.connect(() => {
			var dialog = new DonationWindow();
			dialog.set_transient_for(this);
			dialog.show_all();
			dialog.run();
			dialog.destroy();
		});

		//btn_about
		btn_about = new Gtk.ToolButton.from_stock ("gtk-about");
		btn_about.label = _("About");
		btn_about.set_tooltip_text (_("Application Info"));
		btn_about.icon_widget = get_shared_icon("", "help-info.svg", 32);
		toolbar_bottom.add(btn_about);

		btn_about.clicked.connect (btn_about_clicked);
	}

	private void btn_about_clicked () {
		var dialog = new AboutWindow();
		dialog.set_transient_for (this);

		dialog.authors = {
			"Tony George:teejeetech@gmail.com"
		};

		dialog.translators = {
			"giulux (Italian)",
			"Jorge Jamhour (Brazilian Portuguese):https://launchpad.net/~jorge-jamhour",
			"B. W. Knight (Korean):https://launchpad.net/~kbd0651",
			"Rodion R. (Russian):https://launchpad.net/~r0di0n"
		};

		dialog.documenters = null;
		dialog.artists = null;
		dialog.donations = null;

		dialog.program_name = AppName;
		dialog.comments = _("System migration toolkit for Ubuntu-based distributions");
		dialog.copyright = "Copyright © 2014 Tony George (%s)".printf(AppAuthorEmail);
		dialog.version = AppVersion;
		dialog.logo = get_app_icon(128);

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.website = "http://teejeetech.in";
		dialog.website_label = "http://teejeetech.blogspot.in";

		dialog.initialize();
		dialog.show_all();
	}

	private void set_bold_font_for_buttons() {
		//set bold font for some buttons
		foreach(Button btn in new Button[] {
			btn_backup_ppa_exec, btn_backup_packages_exec, btn_backup_config_exec, btn_backup_theme_exec,
			btn_restore_ppa_exec, btn_restore_packages_exec, btn_restore_config_exec, btn_restore_theme_exec
		}) {
			foreach(Widget widget in btn.get_children()) {
				if (widget is Label) {
					Label lbl = (Label)widget;
					lbl.set_markup(lbl.label);
				}
			}
		}
	}

	private void notebook_switch_page (Widget page, uint new_page) {
		uint old_page = notebook.page;
		if (old_page == -1) {
			return;
		}

		if (new_page == Page.HOME) {
			toolbar_bottom.visible = true;
			resize(def_width, def_height);
			title = AppName + " v" + AppVersion;

			lbl_status.visible = false;
			progressbar.visible = false;
			notebook.sensitive = true;
		}
		else {
			toolbar_bottom.visible = false;
			resize(ex_width, ex_height);
		}
	}

	private void show_home_page() {
		notebook.page = Page.HOME;
	}

	private void tv_packages_refresh() {
		ListStore model = new ListStore(4, typeof(bool), typeof(Package), typeof(Gdk.Pixbuf), typeof(string));

		var pkg_list = new ArrayList<Package>();
		if (pkg_list_user != null) {
			foreach(Package pkg in pkg_list_user.values) {
				pkg_list.add(pkg);
			}
		}
		CompareDataFunc<Package> func = (a, b) => {
			return strcmp(a.name, b.name);
		};
		pkg_list.sort((owned)func);

		//status icons
		Gdk.Pixbuf pix_green = null;
		Gdk.Pixbuf pix_gray = null;
		Gdk.Pixbuf pix_red = null;
		Gdk.Pixbuf pix_yellow = null;
		Gdk.Pixbuf pix_blue = null;
		Gdk.Pixbuf pix_status = null;

		try {
			pix_green = new Gdk.Pixbuf.from_file(App.share_dir + "/aptik/images/item-green.png");
			pix_gray = new Gdk.Pixbuf.from_file(App.share_dir + "/aptik/images/item-gray.png");
			pix_red  = new Gdk.Pixbuf.from_file(App.share_dir + "/aptik/images/item-red.png");
			pix_yellow  = new Gdk.Pixbuf.from_file(App.share_dir + "/aptik/images/item-yellow.png");
			pix_blue  = new Gdk.Pixbuf.from_file(App.share_dir + "/aptik/images/item-blue.png");
		}
		catch (Error e) {
			log_error (e.message);
		}

		TreeIter iter;
		string tt = "";
		foreach(Package pkg in pkg_list) {
			tt = "";

			if (is_restore_view) {
				if (pkg.is_installed) {
					tt += _("Installed");
					pix_status = pix_green;
				}
				else {
					tt += _("Available") + ", " + _("Not Installed");
					pix_status = pix_gray;
				}
			}
			else {
				if (pkg.is_installed && pkg.is_default) {
					tt += _("Default - This package is part of the base distribution");
					pix_status = pix_blue;
				}
				else if (pkg.is_installed && pkg.is_manual) {
					tt += _("Extra - This package was installed by user");
					pix_status = pix_green;
				}
				else if (pkg.is_installed && pkg.is_automatic) {
					tt += _("Automatic - This package was installed as a dependency for other packages");
					pix_status = pix_yellow;
				}
				else {
					tt += _("Available") + ", " + _("Not Installed");
					pix_status = pix_gray;
				}
			}

			//add row
			model.append(out iter);
			model.set (iter, 0, pkg.is_selected);
			model.set (iter, 1, pkg);
			model.set (iter, 2, pix_status);
			model.set (iter, 3, tt);
		}

		filter_packages = new TreeModelFilter (model, null);
		filter_packages.set_visible_func(filter_packages_filter);
		tv_packages.set_model (filter_packages);
		tv_packages.columns_autosize();
	}

	private bool filter_packages_filter (Gtk.TreeModel model, Gtk.TreeIter iter) {
		Package pkg;
		model.get (iter, 1, out pkg, -1);
		bool display = true;

		string search_string = txt_filter.text.strip().down();
		if ((search_string != null) && (search_string.length > 0)) {
			try {
				Regex regexName = new Regex (search_string, RegexCompileFlags.CASELESS);
				MatchInfo match_name;
				MatchInfo match_desc;
				if (!regexName.match (pkg.name, 0, out match_name) && !regexName.match (pkg.description, 0, out match_desc)) {
					display = false;
				}
			}
			catch (Error e) {
				//ignore
			}
		}

		switch (cmb_pkg_status.active) {
		case 0: //all
			//exclude nothing
			break;
		case 1: //Installed
			if (!pkg.is_installed) {
				display = false;
			}
			break;
		case 2: //Installed, Distribution
			if (!(pkg.is_installed && pkg.is_default)) {
				display = false;
			}
			break;
		case 3: //Installed, User
			if (!(pkg.is_installed && pkg.is_manual)) {
				display = false;
			}
			break;
		case 4: //Installed, Automatic
			if (!(pkg.is_installed && pkg.is_automatic)) {
				display = false;
			}
			break;
		case 5: //NotInstalled
			if (pkg.is_installed) {
				display = false;
			}
			break;
		case 6: //selected
			if (!pkg.is_selected) {
				display = false;
			}
			break;
		case 7: //unselected
			if (pkg.is_selected) {
				display = false;
			}
			break;
		}

		switch (cmb_pkg_section.active) {
		case 0: //all
			//exclude nothing
			break;
		default:
			if (pkg.section != gtk_combobox_get_value(cmb_pkg_section, 0, ""))
			{
				display = false;
			}
			break;
		}

		return display;
	}

	private void tv_ppa_refresh() {
		ListStore model = new ListStore(4, typeof(bool), typeof(Ppa), typeof(Gdk.Pixbuf), typeof(string));

		//sort ppa list
		var ppa_list = new ArrayList<Ppa>();
		foreach(Ppa ppa in ppa_list_user.values) {
			ppa_list.add(ppa);
		}
		CompareDataFunc<Ppa> func = (a, b) => {
			return strcmp(a.name, b.name);
		};
		ppa_list.sort((owned)func);

		//status icons
		Gdk.Pixbuf pix_enabled = null;
		Gdk.Pixbuf pix_missing = null;
		Gdk.Pixbuf pix_unused = null;
		Gdk.Pixbuf pix_status = null;

		try {
			pix_enabled = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-green.png");
			pix_missing = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-gray.png");
			pix_unused = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-yellow.png");
		}
		catch (Error e) {
			log_error (e.message);
		}

		TreeIter iter;
		string tt = "";
		foreach(Ppa ppa in ppa_list) {
			//check status
			if (ppa.is_installed) {
				if (ppa.description.length > 0) {
					pix_status = pix_enabled;
					tt = _("PPA is Enabled (%d installed packages)").printf(ppa.description.split(" ").length);
				}
				else {
					pix_status = pix_unused;
					tt = _("PPA is Enabled (%d installed packages)").printf(0);
				}
			}
			else {
				pix_status = pix_missing;
				tt = _("PPA is Not Added");
			}

			//add row
			model.append(out iter);
			model.set (iter, 0, ppa.is_selected);
			model.set (iter, 1, ppa);
			model.set (iter, 2, pix_status);
			model.set (iter, 3, tt);
		}

		tv_ppa.set_model(model);
		tv_ppa.columns_autosize();
	}

	private void tv_theme_refresh() {
		ListStore model = new ListStore(4, typeof(bool), typeof(Theme), typeof(Gdk.Pixbuf), typeof(string));

		//status icons
		Gdk.Pixbuf pix_enabled = null;
		Gdk.Pixbuf pix_missing = null;
		Gdk.Pixbuf pix_status = null;

		try {
			pix_enabled = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-green.png");
			pix_missing = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-gray.png");
		}
		catch (Error e) {
			log_error (e.message);
		}

		TreeIter iter;
		string tt = "";
		foreach(Theme theme in theme_list_user) {
			//check status
			if (theme.is_installed) {
				pix_status = pix_enabled;
				tt = _("Installed");
			}
			else {
				pix_status = pix_missing;
				tt = _("Not Installed");
			}

			//add row
			model.append(out iter);
			model.set (iter, 0, theme.is_selected);
			model.set (iter, 1, theme);
			model.set (iter, 2, pix_status);
			model.set (iter, 3, tt);
		}

		tv_theme.set_model(model);
		tv_theme.columns_autosize();
	}

	private void tv_config_refresh() {
		ListStore model = new ListStore(2, typeof(bool), typeof(AppConfig));
		tv_config.model = model;

		foreach(AppConfig entry in config_list_user) {
			TreeIter iter;
			model.append(out iter);
			model.set (iter, 0, entry.is_selected, 1, entry, -1);
		}
	}

	private void cmb_pkg_status_refresh() {
		log_debug("call: cmb_pkg_status_refresh()");
		var store = new ListStore(1, typeof(string));
		TreeIter iter;
		store.append(out iter);
		store.set (iter, 0, _("All"));
		store.append(out iter);
		store.set (iter, 0, _("Installed"));
		store.append(out iter);
		store.set (iter, 0, _("Installed (dist)"));
		store.append(out iter);
		store.set (iter, 0, _("Installed (user)"));
		store.append(out iter);
		store.set (iter, 0, _("Installed (auto)"));
		store.append(out iter);
		store.set (iter, 0, _("NotInstalled"));
		store.append(out iter);
		store.set (iter, 0, _("(selected)"));
		store.append(out iter);
		store.set (iter, 0, _("(unselected)"));
		cmb_pkg_status.set_model (store);
		cmb_pkg_status.active = 0;
	}

	private void cmb_pkg_section_refresh() {
		log_debug("call: cmb_pkg_section_refresh()");
		var store = new ListStore(1, typeof(string));
		TreeIter iter;
		store.append(out iter);
		store.set (iter, 0, _("All"));
		foreach (string section in App.sections) {
			store.append(out iter);
			store.set (iter, 0, section);
		}
		cmb_pkg_section.set_model (store);
		cmb_pkg_section.active = 0;
	}

	private void cmb_filters_connect() {
		cmb_pkg_status.changed.connect(tv_packages_refilter);
		cmb_pkg_section.changed.connect(tv_packages_refilter);
		log_debug("connected: combo events");
	}

	private void cmb_filters_disconnect() {
		cmb_pkg_status.changed.disconnect(tv_packages_refilter);
		cmb_pkg_section.changed.disconnect(tv_packages_refilter);
		log_debug("disconnected: combo events");
	}

	private void tv_packages_refilter() {
		log_debug("call: tv_packages_refilter()");
		//gtk_set_busy(true,this);
		//vbox_actions.sensitive = false;

		filter_packages.refilter();
		//log_debug("end: refilter();");

		//gtk_set_busy(false,this);
		//vbox_actions.sensitive = true;
	}

	private bool check_backup_folder() {
		if ((App.backup_dir != null) && dir_exists (App.backup_dir)) {
			return true;
		}
		else {
			string title = _("Backup Directory Not Selected");
			string msg = _("Please select the backup directory");
			gtk_messagebox(title, msg, this, false);
			return false;
		}
	}

	private bool check_backup_file(string file_name) {
		if (check_backup_folder()) {
			string backup_file = App.backup_dir + file_name;
			var f = File.new_for_path(backup_file);
			if (!f.query_exists()) {
				string title = _("File Not Found");
				string msg = _("File not found in backup directory") + " - %s".printf(file_name);
				gtk_messagebox(title, msg, this, true);
				return false;
			}
			else {
				return true;
			}
		}
		else {
			return false;
		}
	}

	private bool check_backup_subfolder(string folder_name) {
		if (check_backup_folder()) {
			string folder = App.backup_dir + folder_name;
			var f = File.new_for_path(folder);
			if (!f.query_exists()) {
				string title = _("Folder Not Found");
				string msg = _("Folder not found in backup directory") + " - %s".printf(folder_name);
				gtk_messagebox(title, msg, this, true);
				return false;
			}
			else {
				return true;
			}
		}
		else {
			return false;
		}
	}

	/* PPA */

	private void btn_backup_ppa_clicked() {
		if (!check_backup_folder()) {
			return;
		}

		string status = _("Checking installed PPAs...");
		progress_begin(status);

		try {
			is_running = true;
			Thread.create<void> (btn_backup_ppa_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while (is_running) {
			update_progress(status);
		}

		progress_hide();

		//un-select unused PPAs
		foreach(Ppa ppa in ppa_list_user.values) {
			if (ppa.description.length == 0) {
				ppa.is_selected = false;
			}
		}

		is_restore_view = false;
		tv_ppa_refresh();
		btn_backup_ppa_exec.visible = true;
		btn_restore_ppa_exec.visible = false;
		title = _("Backup Software Sources");

		notebook.page = Page.PPA;
	}

	private void btn_backup_ppa_clicked_thread() {
		App.read_package_info();
		ppa_list_user = App.ppa_list_master;
		is_running = false;
	}

	private void btn_backup_ppa_exec_clicked() {
		//check if no action required
		bool none_selected = true;
		foreach(Ppa ppa in ppa_list_user.values) {
			if (ppa.is_selected) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("No PPA Selected");
			string msg = _("Select the PPAs to backup");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		gtk_set_busy(true, this);

		if (save_ppa_list_selected(true)) {
			show_home_page();
		}

		gtk_set_busy(false, this);
	}


	private void btn_restore_ppa_clicked() {
		if (!check_backup_folder()) {
			return;
		}
		if (!check_backup_file("ppa.list")) {
			return;
		}

		string status = _("Checking installed PPAs...");
		progress_begin(status);

		try {
			is_running = true;
			Thread.create<void> (btn_restore_ppa_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while (is_running) {
			update_progress(status);
		}

		progress_hide();

		is_restore_view = true;
		tv_ppa_refresh();
		btn_backup_ppa_exec.visible = false;
		btn_restore_ppa_exec.visible = true;

		title = _("Restore Software Sources");

		notebook.page = Page.PPA;
	}

	private void btn_restore_ppa_clicked_thread() {
		App.read_package_info();
		ppa_list_user = App.ppa_list_master;
		is_running = false;
	}

	private void btn_restore_ppa_exec_clicked() {
		//check if no action required
		bool none_selected = true;
		foreach(Ppa ppa in ppa_list_user.values) {
			if (ppa.is_selected && !ppa.is_installed) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("Nothing To Do");
			string msg = _("Selected PPAs are already enabled on this system");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		if (!check_internet_connectivity()) {
			string title = _("Error");
			string msg = _("Internet connection is not active. Please check the connection and try again.");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		string status = _("Adding PPAs...");
		progress_begin(status);

		//save ppa.list
		string file_name = "ppa.list";
		bool is_success = save_ppa_list_selected(false);
		if (!is_success) {
			string title = _("Error");
			string msg = _("Failed to write")  + " '%s'".printf(file_name);
			gtk_messagebox(title, msg, this, false);
			return;
		}

		string cmd = "";

		//add PPAs
		cmd += "echo ''\n";
		foreach(Ppa ppa in ppa_list_user.values) {
			if (ppa.is_selected && !ppa.is_installed) {
				cmd += "add-apt-repository -y ppa:%s\n".printf(ppa.name);
				cmd += "echo ''\n";
			}
		}

		//iconify();
		gtk_do_events();

		cmd += "echo ''\n";
		cmd += "echo '" + _("Updating Package Information...") + "'\n";
		cmd += "echo ''\n";
		cmd += "apt-get update\n"; //> /dev/null 2>&1
		cmd += "echo ''\n";
		cmd += "\n\necho '" + _("Finished adding PPAs") + "'";
		cmd += "\necho '" + _("Close window to exit...") + "'";
		cmd += "\nread dummy";
		execute_command_script_in_terminal_sync(create_temp_bash_script(cmd));

		//deiconify();
		gtk_do_events();

		//verify
		status = _("Checking installed PPAs...");
		progress_begin(status);

		App.update_info_for_repository();

		string error_list = "";
		foreach(Ppa ppa in App.ppa_list_master.values) {
			if (ppa.is_selected && !ppa.is_installed) {
				//if (!ppa_list_new.has_key(ppa.name)){
				//	error_list += "%s\n".printf(ppa.name);
				//}
				//TODO: Check if PPA addition failed
			}
		}

		//show message
		if (error_list.length == 0) {
			string title = _("Finished");
			string msg = _("PPAs added successfully");
			gtk_messagebox(title, msg, this, false);
		}
		else {
			string title = _("Finished with Errors");
			string msg = _("Following PPAs could not be added") + ":\n\n%s\n".printf(error_list);
			gtk_messagebox(title, msg, this, false);
		}

		show_home_page();
	}

	private bool save_ppa_list_selected(bool show_on_success) {
		string file_name = "ppa.list";

		bool is_success = App.save_ppa_list_selected();

		if (is_success) {
			if (show_on_success) {
				string title = _("Finished");
				string msg = _("Backup created successfully") + ".\n";
				msg += _("List saved with file name") + " '%s'".printf(file_name);
				gtk_messagebox(title, msg, this, false);
			}
		}
		else {
			string title = _("Error");
			string msg = _("Failed to write")  + " '%s'".printf(file_name);
			gtk_messagebox(title, msg, this, true);
		}

		return is_success;
	}

	/* Packages */

	private void btn_backup_packages_clicked() {
		if (!check_backup_folder()) {
			return;
		}

		string status = _("Checking installed packages...");
		progress_begin(status);

		try {
			is_running = true;
			Thread.create<void> (btn_backup_packages_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while (is_running) {
			update_progress(status);
		}

		progress_hide();

		if (App.default_list_missing) {
			string title = _("File Missing");
			string msg = _("The list of default packages is missing on this system") + ":\n'%s'\n\n".printf(Main.DEFAULT_PKG_LIST_FILE);
			msg += _("It is not possible to determine whether a package was installed by you, or whether it was installed along with the Linux distribution.") + "\n\n";
			msg += _("All top-level installed packages have been selected by default.") + " ";
			msg += _("Please un-select the packages that are not required.") + "\n";
			gtk_messagebox(title, msg, this, false);
		}

		//select manual
		foreach(Package pkg in pkg_list_user.values) {
			pkg.is_selected = pkg.is_manual;
		}

		is_restore_view = false;

		btn_backup_packages_exec.show();
		btn_backup_packages_exec.visible = true;

		btn_restore_packages_exec.visible = false;

		tv_packages_refresh();

		//disconnect combo events
		cmb_filters_disconnect();
		//refresh combos
		cmb_pkg_status_refresh();
		cmb_pkg_status.active = 1;
		cmb_pkg_section_refresh();
		//re-connect combo events
		cmb_filters_connect();

		tv_packages_refilter();

		title = _("Backup Software Selections");

		notebook.page = Page.PACKAGES;

		//fix for column header resize issue
		gtk_do_events();
		//cmb_pkg_type.active = 1;
		//cmb_pkg_type.active = 0;
	}

	private void btn_backup_packages_clicked_thread() {
		App.read_package_info();
		pkg_list_user = App.pkg_list_master;
		is_running = false;
	}

	private void btn_backup_packages_exec_clicked() {
		//check if no action required
		bool none_selected = true;
		foreach(Package pkg in pkg_list_user.values) {
			if (pkg.is_selected) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("No Packages Selected");
			string msg = _("Select the packages to backup");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		gtk_set_busy(true, this);

		save_package_list_installed();
		if (save_package_list_selected(true)) {
			show_home_page();
		}

		gtk_set_busy(false, this);
	}

	private bool save_package_list_selected(bool show_on_success) {
		string file_name = Main.PKG_LIST_BAK;

		//filter the list of packages
		var pkg_list = pkg_list_user;

		//save it
		bool is_success = App.save_package_list_selected();

		if (is_success) {
			if (show_on_success) {
				string title = _("Finished");
				string msg = _("Backup created successfully") + ".\n";
				msg += _("List saved with file name") + " '%s'".printf(file_name);
				gtk_messagebox(title, msg, this, false);
			}
		}
		else {
			string title = _("Error");
			string msg = _("Failed to write")  + " '%s'".printf(file_name);
			gtk_messagebox(title, msg, this, true);
		}

		return is_success;
	}

	private bool save_package_list_installed() {
		string file_name = Main.PKG_LIST_INSTALLED_BAK;

		bool is_success = App.save_package_list_installed();

		if (!is_success) {
			string title = _("Error");
			string msg = _("Failed to write") + " '%s'".printf(file_name);
			gtk_messagebox(title, msg, this, true);
		}

		return is_success;
	}


	private void btn_restore_packages_clicked() {
		if (!check_backup_folder()) {
			return;
		}
		if (!check_backup_file("packages.list")) {
			return;
		}

		string status = _("Checking installed and available packages...");
		progress_begin(status);

		try {
			is_running = true;
			Thread.create<void> (btn_restore_packages_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while (is_running) {
			update_progress(status);
		}

		//select packages from backup file
		string missing = "";
		var list_bak = App.read_package_list();
		foreach(Package pkg in pkg_list_user.values) {
			pkg.is_selected = false;
		}
		foreach(string pkg_name in list_bak) {
			if (pkg_list_user.has_key(pkg_name)) {
				pkg_list_user[pkg_name].is_selected = true;
			}
			else {
				missing += "%s ".printf(pkg_name);
			}
		}

		progress_hide();

		is_restore_view = true;
		btn_backup_packages_exec.visible = false;
		btn_restore_packages_exec.visible = true;

		title = _("Restore Software Selections");

		tv_packages_refresh();

		//disconnect combo events
		cmb_filters_disconnect();
		//refresh combos
		cmb_pkg_status_refresh();
		cmb_pkg_status.active = 6;
		cmb_pkg_section_refresh();
		//re-connect combo events
		cmb_filters_connect();

		tv_packages_refilter();

		notebook.page = Page.PACKAGES;

		if (missing.length > 0) {
			var title = _("Missing Packages");
			var msg = _("Following packages are not available (missing PPA):\n\n%s").printf(missing);
			gtk_messagebox(title, msg, this, false);
		}

		//fix for column header resize issue
		gtk_do_events();
		//cmb_pkg_status.active = 1;
		//cmb_pkg_status.active = 0;
	}

	private void btn_restore_packages_clicked_thread() {
		App.read_package_info();
		pkg_list_user = App.pkg_list_master;
		is_running = false;
	}

	private void btn_restore_packages_exec_clicked() {
		//check if no action required
		bool none_selected = true;
		foreach(Package pkg in pkg_list_user.values) {
			if (pkg.is_selected && pkg.is_available && !pkg.is_installed) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("Nothing To Do");
			string msg = _("There are no packages selected for installation");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		if (!check_internet_connectivity()) {
			string title = _("Error");
			string msg = _("Internet connection is not active. Please check the connection and try again.");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		//save packages.list
		string file_name = "packages.list";
		progress_begin(_("Saving") + " '%s'".printf(file_name));
		bool is_success = save_package_list_selected(false);
		if (!is_success) {
			string title = _("Error");
			string msg = _("Failed to write file")  + ": '%s'".printf(file_name);
			gtk_messagebox(title, msg, this, true);
			return;
		}

		//check list of packages to install
		string list_install = "";
		string list_unknown = "";

		foreach(Package pkg in pkg_list_user.values) {
			if (pkg.is_selected && pkg.is_available && !pkg.is_installed) {
				list_install += " %s".printf(pkg.name);
			}
		}
		foreach(Package pkg in pkg_list_user.values) {
			if (pkg.is_selected && !pkg.is_available && !pkg.is_installed) {
				list_unknown += " %s".printf(pkg.name);
			}
		}

		list_install = list_install.strip();
		list_unknown = list_unknown.strip();

		if (list_install.length == 0) {
			string title = _("Nothing To Do");
			string msg = "";
			if (list_unknown.length > 0) {
				msg += _("Following packages are NOT available") + ":\n\n" + list_unknown + "\n\n";
			}
			msg += _("There are no packages selected for installation");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		progress_begin(_("Installing packages..."));

		gtk_do_events();

		string cmd = "apt-get install %s".printf(list_install);
		cmd += "\necho ''";
		cmd += "\necho '" + _("Finished installing packages") + ".'";
		cmd += "\necho '" + _("Close window to exit...") + "'";
		cmd += "\nread dummy";
		execute_command_script_in_terminal_sync(create_temp_bash_script(cmd));
		//success/error will be displayed by apt-get in terminal

		gtk_do_events();

		show_home_page();
	}

	/* APT Cache */

	private void btn_backup_cache_clicked() {
		if (!check_backup_folder()) {
			return;
		}

		string archives_dir = App.backup_dir + "archives";

		string status = _("Preparing") + "...";
		progress_begin(status);

		App.backup_apt_cache();
		while (App.is_running) {
			update_progress(_("Copying"));
		}

		//finish ----------------------------------

		progress_hide("Finished");

		string title = _("Finished");
		string msg = _("Packages copied successfully") + ".\n";
		msg += _("%ld packages in backup").printf(get_file_count(archives_dir));
		gtk_messagebox(title, msg, this, false);

		show_home_page();
	}

	private void btn_restore_cache_clicked() {
		if (!check_backup_folder()) {
			return;
		}

		//check 'archives' directory
		string archives_dir = App.backup_dir + "archives";
		var f = File.new_for_path(archives_dir);
		if (!f.query_exists()) {
			string title = _("Files Not Found");
			string msg = _("Cache backup not found in backup directory");
			gtk_messagebox(title, msg, this, true);
			return;
		}

		string status = _("Preparing") + "...";
		progress_begin(status);

		App.restore_apt_cache();
		while (App.is_running) {
			update_progress(_("Copying"));
		}

		//finish ----------------------------------

		progress_hide("Finished");

		string title = _("Finished");
		string msg = _("Packages copied successfully") + ".\n";
		msg += _("%ld packages in cache").printf(get_file_count("/var/cache/apt/archives") - 2); //excluding 'lock' and 'partial'
		gtk_messagebox(title, msg, this, false);

		show_home_page();
	}

	/* App Settings */

	private void btn_backup_config_clicked() {
		progress_hide();

		if (!check_backup_folder()) {
			return;
		}

		gtk_set_busy(true, this);

		is_restore_view = false;
		config_list_user = App.list_app_config_directories_from_home();
		tv_config_refresh();
		btn_backup_config_exec.visible = true;
		btn_restore_config_exec.visible = false;
		btn_reset_config_exec.visible = false;
		title = _("Backup Application Settings");

		notebook.page = Page.CONFIGS;

		gtk_set_busy(false, this);
	}

	private void btn_backup_config_exec_clicked() {
		//check if no action required
		bool none_selected = true;
		foreach(AppConfig config in config_list_user) {
			if (config.is_selected) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("No Directories Selected");
			string msg = _("Select the directories to backup");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		//begin
		string status = _("Preparing") + "...";
		progress_begin(status);

		//backup
		App.backup_app_settings(config_list_user);
		while (App.is_running) {
			update_progress(_("Zipping"));
		}

		//finish ----------------------------------

		progress_hide("Finished");

		string title = _("Finished");
		string msg = _("Backups created successfully");
		gtk_messagebox(title, msg, this, false);

		show_home_page();
	}

	private void btn_restore_config_clicked() {
		progress_hide();

		gtk_set_busy(true, this);

		if (check_backup_file(App.app_settings_zip_name)) {
			is_restore_view = true;
			config_list_user = App.list_app_config_directories_from_backup();
			tv_config_refresh();
			btn_backup_config_exec.visible = false;
			btn_restore_config_exec.visible = true;
			btn_reset_config_exec.visible = true;

			title = _("Restore Application Settings");

			notebook.page = Page.CONFIGS;
		}

		gtk_set_busy(false, this);
	}

	private void btn_restore_config_exec_clicked() {
		//check if no action required
		bool none_selected = true;
		foreach(AppConfig conf in config_list_user) {
			if (conf.is_selected) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("Nothing To Do");
			string msg = _("Please select the directories to restore");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		//begin
		string status = _("Preparing") + "...";
		progress_begin(status);

		//prompt for confirmation
		string title = _("Warning");
		string msg = _("Selected directories will be replaced with files from backup.") + "\n" + ("Do you want to continue?");
		var dlg = new Gtk.MessageDialog.with_markup(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, msg);
		dlg.set_title(title);
		dlg.set_default_size (200, -1);
		dlg.set_transient_for(this);
		dlg.set_modal(true);
		int response = dlg.run();
		dlg.destroy();

		if (response == Gtk.ResponseType.NO) {
			progress_hide("Cancelled");
			return;
		}

		//extract
		App.restore_app_settings(config_list_user);
		while (App.is_running) {
			update_progress(_("Extracting"));
		}

		//update ownership
		progress_begin(_("Updating file ownership") + "...");
		App.update_ownership(config_list_user);

		//finish ----------------------------------

		progress_hide("Finished");

		title = _("Finished");
		msg = _("Application settings restored successfully");
		gtk_messagebox(title, msg, this, false);

		show_home_page();
	}

	private void btn_reset_config_exec_clicked() {
		//check if no action required
		bool none_selected = true;
		foreach(AppConfig conf in config_list_user) {
			if (conf.is_selected) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("Nothing To Do");
			string msg = _("Please select the directories to reset");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		//begin
		string status = _("Preparing") + "...";
		progress_begin(status);

		//prompt for confirmation
		string title = _("Warning");
		string msg = _("Selected directories will be deleted.") + "\n" + ("Do you want to continue?");
		var dlg = new Gtk.MessageDialog.with_markup(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, msg);
		dlg.set_title(title);
		dlg.set_default_size (200, -1);
		dlg.set_transient_for(this);
		dlg.set_modal(true);
		int response = dlg.run();
		dlg.destroy();

		if (response == Gtk.ResponseType.NO) {
			progress_hide("Cancelled");
			return;
		}

		//extract
		App.reset_app_settings(config_list_user);
		while (App.is_running) {
			update_progress(_("Deleting"));
		}

		//finish
		progress_hide("Finished");
		title = _("Finished");
		msg = _("Selected directories were deleted successfully");
		gtk_messagebox(title, msg, this, false);

		show_home_page();
	}


	/* Themes */

	private void btn_backup_theme_clicked() {
		progress_hide();

		if (!check_backup_folder()) {
			return;
		}

		gtk_set_busy(true, this);

		is_restore_view = false;
		theme_list_user = App.list_all_themes();
		tv_theme_refresh();
		btn_backup_theme_exec.visible = true;
		btn_restore_theme_exec.visible = false;
		title = _("Backup Themes");

		notebook.page = Page.THEMES;

		gtk_set_busy(false, this);
	}

	private void btn_backup_theme_exec_clicked() {
		//check if no action required
		bool none_selected = true;
		foreach(Theme theme in theme_list_user) {
			if (theme.is_selected) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("No Themes Selected");
			string msg = _("Select the themes to backup");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		string status = _("Preparing") + "...";
		progress_begin(status);

		//get total file count
		App.progress_total = 0;
		App.progress_count = 0;
		foreach(Theme theme in theme_list_user) {
			if (theme.is_selected) {
				App.progress_total += (int) get_file_count(theme.system_path);
			}
		}

		//zip themes
		foreach(Theme theme in theme_list_user) {
			if (theme.is_selected) {
				App.zip_theme(theme);
				while (App.is_running) {
					update_progress(_("Archiving"));
				}
			}
		}

		//finish ----------------------------------

		progress_hide("Finished");
		string title = _("Finished");
		string msg = _("Backups created successfully");
		gtk_messagebox(title, msg, this, false);
		show_home_page();
	}

	private void btn_restore_theme_clicked() {
		progress_hide();

		gtk_set_busy(true, this);

		if (check_backup_subfolder("themes") || check_backup_subfolder("icons") ) {
			is_restore_view = true;
			theme_list_user = App.get_all_themes_from_backup();
			tv_theme_refresh();
			btn_backup_theme_exec.visible = false;
			btn_restore_theme_exec.visible = true;
			title = _("Restore Themes");

			notebook.page = Page.THEMES;
		}

		gtk_set_busy(false, this);
	}

	private void btn_restore_theme_exec_clicked() {
		//check if no action required
		bool none_selected = true;
		foreach(Theme theme in theme_list_user) {
			if (theme.is_selected && !theme.is_installed) {
				none_selected = false;
				break;
			}
		}
		if (none_selected) {
			string title = _("Nothing To Do");
			string msg = _("Selected themes are already installed");
			gtk_messagebox(title, msg, this, false);
			return;
		}

		//begin
		string status = _("Preparing") + "...";
		progress_begin(status);

		//get total file count
		App.progress_total = 0;
		App.progress_count = 0;
		foreach(Theme theme in theme_list_user) {
			if (theme.is_selected && !theme.is_installed) {
				string cmd = "tar -tvf '%s'".printf(theme.zip_file_path);
				string txt = execute_command_sync_get_output(cmd);
				App.progress_total += txt.split("\n").length;
			}
		}

		//unzip themes
		foreach(Theme theme in theme_list_user) {
			if (theme.is_selected && !theme.is_installed) {
				App.unzip_theme(theme);
				while (App.is_running) {
					update_progress(_("Extracting"));
				}
				App.update_permissions(theme.system_path);
			}
		}

		//finish ----------------------------------

		progress_hide("Finished");

		string title = _("Finished");
		string msg = _("Themes restored successfully");
		gtk_messagebox(title, msg, this, false);
		show_home_page();
	}

	/* Misc */

	private void btn_take_ownership_clicked() {
		progress_hide();

		string title = _("Change Ownership");
		string msg = _("Owner will be changed to '%s' (uid=%d) for files in directory '%s'").printf(App.user_login, App.user_uid, App.user_home);
		msg += "\n\n" + _("Continue?");

		var dlg = new Gtk.MessageDialog.with_markup(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, msg);
		dlg.set_title(title);
		dlg.set_default_size (200, -1);
		dlg.set_transient_for(this);
		dlg.set_modal(true);
		int response = dlg.run();
		dlg.destroy();
		gtk_do_events();

		if (response == Gtk.ResponseType.YES) {
			gtk_set_busy(true, this);

			bool is_success = App.take_ownership();
			if (is_success) {
				title = _("Success");
				msg = _("You are now the owner of all files in your home directory");
				gtk_messagebox(title, msg, this, false);
			}
			else {
				title = _("Error");
				msg = _("Failed to change file ownership");
				gtk_messagebox(title, msg, this, true);
			}

			gtk_set_busy(false, this);
		}
	}

	private void progress_begin(string message = "") {
		lbl_status.visible = true;
		progressbar.visible = true;

		App.progress_total = 0;
		progressbar.fraction = 0.0;
		lbl_status.label = message;

		notebook.sensitive = false;
		toolbar_bottom.visible = false;

		gtk_set_busy(true, this);
		//gtk_do_events();
	}

	private void progress_hide(string message = "") {
		lbl_status.visible = false;
		progressbar.visible = false;

		//progressbar.fraction = 0.0; //not required, gives warnings
		//lbl_status.label = message;

		notebook.sensitive = true;
		//toolbar_bottom.visible = true; //depends

		gtk_set_busy(false, this);
		gtk_do_events();
	}

	private void progress_end(string message = "") {
		progressbar.fraction = 1.0;
		lbl_status.label = message;

		lbl_status.visible = true;
		progressbar.visible = true;

		notebook.sensitive = true;
		//toolbar_bottom.visible = true; //depends

		gtk_set_busy(false, this);
		gtk_do_events();
	}

	private void update_progress(string message) {
		if (App.progress_total > 0) {
			progressbar.fraction = App.progress_count / (App.progress_total * 1.0);
			lbl_status.label = message + ": %s".printf(App.status_line);
			gtk_do_events();
			Thread.usleep ((ulong) 0.1 * 1000000);
		}
		else {
			progressbar.pulse();
			lbl_status.label = message;
			gtk_do_events();
			Thread.usleep ((ulong) 200000);
		}
	}

	public enum Page {
		HOME = 0,
		PPA = 1,
		PACKAGES = 2,
		CONFIGS = 3,
		THEMES = 4
	}
}


