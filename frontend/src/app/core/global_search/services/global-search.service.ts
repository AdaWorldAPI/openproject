//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, Injector } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';

@Injectable()
export class GlobalSearchService {
  private _currentTab$:BehaviorSubject<string>;
  private _tabs$:BehaviorSubject<TabDefinition[]>;

  public currentTab$:Observable<string>;
  public tabs$:Observable<TabDefinition[]>;

  public set currentTab(tabId:string) {
    this._currentTab$.next(tabId);
  }

  public get currentTab():string {
    return this._currentTab$.value;
  }

  constructor(
    protected I18n:I18nService,
    protected injector:Injector,
    protected PathHelper:PathHelperService,
    protected currentProjectService:CurrentProjectService,
  ) {
    this._currentTab$ = new BehaviorSubject<string>(this.initialTab());
    this._tabs$ = new BehaviorSubject<TabDefinition[]>(this.defaultTabs());
    this.currentTab$ = this._currentTab$.asObservable();
    this.tabs$ = this._tabs$.asObservable();
  }

  public submitSearch(query?:string, scope?:string):void {
    const searchQuery = query ?? this.currentQuery();
    const searchScope = scope ?? this.currentTab;
    const path = this.searchPath(searchScope);
    const params = this.searchQueryParams(searchQuery, searchScope);
    window.location.href = `${path}?${params}`;
  }

  public searchPath(scope:string) {
    let searchPath:string = this.PathHelper.staticBase;
    if (this.currentProjectService.path && scope !== 'all') {
      searchPath = this.currentProjectService.path;
    }
    return `${searchPath}/search`;
  }

  private searchQueryParams(query:string, scope:string):string {
    const params = new URLSearchParams(window.location.search);
    params.set('q', query);
    params.set('scope', scope);

    // Filter work packages by default
    if (!params.get('filter')) {
      params.set('filter', 'work_packages');
    }

    return params.toString();
  }

  private currentQuery():string {
    const params = new URLSearchParams(window.location.search);
    return params.get('q') || '';
  }

  private initialTab():string {
    const params = new URLSearchParams(window.location.search);
    return params.get('filter') || 'work_packages';
  }

  private defaultTabs():TabDefinition[] {
    return [
      { id: 'all', name: this.I18n.t('js.label_all') },
      { id: 'work_packages', name: this.I18n.t('js.work_packages.label_work_package_plural') },
    ];
  }
}
