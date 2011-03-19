<!---
	Name         : cache
	Author       : Juan Boyce
	Created      : July 23, 2010
	Last Updated : July 23 , 2010
	History      : Initial Alpha release (rg 07/23/10)
				 
	Purpose		 : load html fragments into memory
--->
<cfcomponent displayname="HTML Cache">
	<cfsetting showdebugoutput="false">
	<cfscript>
		this.rootPath = GetDirectoryFromPath(GetCurrentTemplatePath()) & "../";
	</cfscript>
	<!--- 
		function: getNavStruct
		in: void
		out: struct containing html
		notes: 
	 --->
	<cffunction name="getNavStruct" access="public" output="no" returntype="struct">
        <cfscript>
			var navCache=StructNew();
            var s=0;
			var tag='';
			var atts='';
			var navHtm = FileRead( this.rootPath & 'includes/nav.htm');
            var l=Len(navHtm);
            while( Find('<li',navHtm,s) gt 0 ){
                tag=REFind('<li.*?>',navHtm,s,true);
				s=tag.pos[1]+2;
				atts=Mid(navHtm,tag.pos[1],tag.len[1]);
                m=REFind('href="[^"]+"',navHtm,s,true);
                k = Replace(Mid(navHtm,m.pos[1]+6,m.len[1]-7),'/','','all');
                if( k eq "" )
                    k = "home";
				if( FindNoCase('class="',atts ) ){
					s = Find('"',navHtm,s);
					navCache[k] = Left(navHtm,s) & 'active ' & Right(navHtm, l-s);
				} else {
					navCache[k] = Left(navHtm,s) & ' class="active"' & Right(navHtm, l-s);
				}
            }
           return navCache;
        </cfscript>
	</cffunction>

	<!--- 
		function: getFooterNav
		in: void
		out: html
		notes: 
	 --->
	<cffunction name="getFooterNav" access="public" output="no" returntype="string">
        <cfscript>
			var navHtm = FileRead( this.rootPath & 'includes/nav.htm');
           return Replace(navHtm,'tabs','footer-nav');
        </cfscript>
	</cffunction>
    
	<cffunction name="getWorksheets" access="public" output="no" returntype="struct">
		<cfset result=StructNew()>
        <cfdirectory action="list" name="qW" directory="#this.rootPath#teachers/worksheets" filter="EB101-*.pdf">
        <cfloop query="qW">
            <cfscript>
			grade=Mid(name,7,3);
            key=Mid(name,11,3);
            if(!StructKeyExists(result,grade)){
                result[grade]=StructNew();
            }
            if(!StructKeyExists(result[grade],key)){
                result[grade][key]=ArrayNew(1);
            }
            ArrayAppend(result[grade][key],name);
            </cfscript>
        </cfloop>
        <cfreturn result>
	</cffunction>
	<!--- 
		function: getSidebarModules
		in: void
		out: struct containing html
		notes: 
	 --->
	<cffunction name="getSidebarModules" access="public" output="no" returntype="struct">
    	<cfset stcMods=StructNew()>
        <cfset path=this.rootPath & "sidebar/">
        <!--- 3 types sidebars: --->
        <cfdirectory action="list" name="qMods" directory="#path#">
        <cfloop query="qMods">
        	<cfset fName=ListFirst(name,'.')>
            <cfset temp=false>
        	<cfswitch expression="#ListLast(name,'.')#">
				<!--- static modules are *.htm; the text is cached "forever" as a string --->
            	<cfcase value="htm">
                	<cfset temp=FileRead(directory & '/' & name)>
                </cfcase>
				<!--- Semi-dynamic modules will be *.cfm and will be a struct of cached strings --->
            	<cfcase value="cfm">
                	<cfset temp=StructNew()>
                    <cfset temp._cfm='../sidebar/'&name>
                </cfcase>
				<!--- Fully-dynamic modules will be *.cfc and will be cfcs that are evaluated at runtime--->
            	<cfcase value="cfc">
                	<cfset temp=CreateObject("component","sidebar.#fName#")>
                </cfcase>
            </cfswitch>
			<cfset stcMods[fName]=temp>
        </cfloop>
        <cfreturn stcMods>
	</cffunction>

	<!--- 
		function: renderModule
		in: moduleName, key
		out: html
		notes: 
	 --->
	<cffunction name="renderModule" access="public" output="no" returntype="string">
    	<cfargument type="string" required="yes" name="moduleName">
    	<cfargument type="string" required="no" name="key" default="">
        <cfif NOT StructKeyExists(application,'sidebar')>
        	<cfset application.sidebar=getSideBarModules()>
        </cfif>
        <cfif StructKeyExists(application.sidebar,moduleName)>
        	<cfif IsSimpleValue(application.sidebar[moduleName])>
            	<cfreturn application.sidebar[moduleName]>
            <cfelseif IsStruct(application.sidebar[moduleName])>
            	<cfif NOT StructKeyExists(application.sidebar[moduleName],key)>
                	<cfsavecontent variable="html">
		            	<cfinclude template="#application.sidebar[moduleName]['_cfm']#">
                    </cfsavecontent>
                    <cfset application.sidebar[moduleName][key]=html>
                 </cfif>
                 <cfreturn application.sidebar[moduleName][key]>
            <cfelseif IsObject(application.sidebar[moduleName])>
            	<cfreturn application.sidebar[moduleName].render()>
            </cfif>
        <cfelse>
        	<cfdump var="#application.sidebar#">
        	<cfthrow message="Module ""#moduleName#"" not exist in cache">
        </cfif>
	</cffunction>

	<!--- 
		function: getLessons
		in: 
		out: query
		notes: 
	 --->
	<cffunction name="getLessons" access="public" output="no" returntype="query">
        <cfset path=this.rootPath & "teachers/lesson_src/">
        <cfset lessonCol="filename,module,lesson,grade,title,content">
    	<cfset qLessons=QueryNew(lessonCol)>
        <cfdirectory action="list" name="qFiles" directory="#path#" filter="*.html">
        <cfloop query="qFiles">
        	<cfset match=REFind('Lesson(\d+)\.(\d+)\((.+?)\)',name,1,true)>
            <cfif ArrayLen(match.len) gt 1>
            	<cfset QueryAddRow(qLessons)>
                <cfloop from="2" to="#ArrayLen(match.len)#" index="i">
                    <cfset QuerySetCell(qLessons,ListGetAt(lessonCol,i),Mid(name,match.pos[i],match.len[i]))>
                </cfloop>
                <cfset content=FileRead(path&name)>
                <cfset match=REFind('<h2>(.+?)</h2>',content,1,true)>
                <cfif ArrayLen(match.len) gt 1>
					<cfset QuerySetCell(qLessons,'title',Mid(content,match.pos[2],match.len[2]))>
                    <cfset content=REReplace(content,'<h2>(.+?)</h2>','')>
                </cfif>
                <cfset QuerySetCell(qLessons,'filename',Left(name,Len(name)-5))>
                <cfset QuerySetCell(qLessons,'content',content)>
            </cfif>
        </cfloop>
        <cfreturn qLessons>
	</cffunction>

	<!--- 
		function: getModules
		in: 
		out: query
		notes: 
	 --->
	<cffunction name="getModules" access="public" output="no" returntype="query">
        <cffile action="read" file="#this.rootPath#content/modules.csv" variable="moduleCSV" charset="utf-8" />
        <cfreturn csvToQuery(moduleCSV,';')>
	</cffunction>

	<!--- 
		function: getInvolved
		in: 
		out: query
		notes: 
	 --->
	<cffunction name="getInvolved" access="public" output="no" returntype="array">
    	<cfargument type="string" name="key" required="yes">
        <cffile action="read" file="#this.rootPath#content/get_involved-#arguments.key#.txt" variable="involvedTips" charset="utf-8" />
        <cfreturn ListToArray(Trim(involvedTips),Chr(10)&Chr(13))>
	</cffunction>
    
	<!--- 
		function: getFamilies
		in: 
		out: struct
		notes: 
	 --->
	<cffunction name="getFamilies" access="public" output="no" returntype="array">
        <cffile action="read" file="#this.rootPath#content/family.txt" variable="familyContent" charset="utf-8" />
        <cfset arrFamily=ArrayNew(1)>
        <cfset mem=ListToArray('heading,intro')>
		<cfset stc=StructNew()>
        <cfset i=0>
        <cfloop list="#familyContent#" delimiters="#Chr(10)##Chr(13)#" index="row">
			<cfset match=REFind('^(.+?)\[(.+?)\]',row,1,true)>
            <cfif match.len[1] gt 0>
                <cfif NOT StructKeyExists(stc,'list')>
                    <cfset stc.list=ArrayNew(1)>
                </cfif>
                <cfset a=StructNew()>
                <cfset a.link=Trim(Mid(row,match.pos[3],match.len[3]))>
                <cfset a.text=Trim(Mid(row,match.pos[2],match.len[2]))>
                <cfset ArrayAppend(stc.list,a)>
                <cfset i=0>
            <cfelse>
                <cfif i eq 0 AND NOT StructIsEmpty(stc)>
                    <cfset ArrayAppend(arrFamily,stc)>
                    <cfset stc=StructNew()>
                </cfif>
                <cfset i+=1>
                <cfset stc[mem[i]]=Trim(row)>
            </cfif>
        </cfloop>
		<cfif NOT StructIsEmpty(stc)>
            <cfset ArrayAppend(arrFamily,stc)>
        </cfif>
        <cfreturn arrFamily>
	</cffunction>

	<!--- 
		function: getLinks
		in: 
		out: query
		notes: 
	 --->
	<cffunction name="getLinks" access="public" output="no" returntype="query">
        <cffile action="read" file="#this.rootPath#content/links.csv" variable="linkCSV" charset="utf-8" />
        <cfreturn csvToQuery(linkCSV)>
	</cffunction>

	<!--- 
		function: getPartners
		in: 
		out: query
		notes: 
	 --->
	<cffunction name="getPartners" access="public" output="no" returntype="query">
        <cffile action="read" file="#this.rootPath#content/partners.csv" variable="partnersCSV" charset="utf-8" />
        <cfset unsortedQuery=csvToQuery(partnersCSV,Chr(9))>
        <cfset sort_col=ArrayNew(1)>
        <cfset cl=unsortedQuery.columnList>
        <cfloop query="unsortedQuery">
            <cfset match=REFindNoCase('(a |the )?[^a-z0-9]*[a-z0-9]',name,1,true)>
        	<cfset ArrayAppend(sort_col,UCase(Mid(name,match.pos[1]+match.len[1]-1,10)))>
        </cfloop>
        <cfset QueryAddColumn(unsortedQuery,'sort_col',sort_col)>
        <cfquery dbtype="query" name="sortedQuery">
        	SELECT #cl#
            FROM unsortedQuery
            ORDER BY sort_col
        </cfquery>
        <cfreturn sortedQuery>
	</cffunction>
    
	<!--- 
		function: csvToQuery
		in: string CSV data
		out: query
		notes: Utility function
	 --->
	<cffunction name="csvToQuery" access="public" output="no" returntype="query">
	    <cfargument name="csvData" required="yes" type="string">
        <cfargument name="fieldDelim" required="no" type="string" default=",">
        <cfargument name="lineDelim" required="no" type="string" default="#Chr(10)##Chr(13)#">
		<cfset csvHeader=ListToArray(ListFirst(csvData,lineDelim),fieldDelim)>
        <cfset tempData=ListDeleteAt(csvData,1,lineDelim)>
        <cfset col=ArrayLen(csvHeader)>
        <cfset qResult=QueryNew( ArrayToList(csvHeader) )>
        <cfloop list="#tempData#" delimiters="#lineDelim#" index="dataRow">
			<cfif Len(Trim(dataRow)) gt 0>
                <cfset QueryAddRow(qResult)>
                <cfloop from="1" to="#col#" index="j">
                    <cfset QuerySetCell(qResult,csvHeader[j],ListGetAt(Trim(dataRow),j,fieldDelim))>
                </cfloop>
            </cfif>
        </cfloop>
        <cfreturn qResult>
	</cffunction>
	<!--- 
		function: getTipOfTheDay
		in: 
		out: struct
		notes: Utility function
	 --->
	<cffunction name="getTipOfTheDay" access="public" output="no" returntype="struct">
		<cfset stcTip=StructNew()>
        <cftry>
            <cfhttp url="http://www.eatright.org/RSS/feed.aspx?feed=tips" charset="utf-8" />
            <cfset feed=XMLParse(cfhttp.FileContent)>
            <cfset item=XMLSearch(feed,'//item[1]')>
            <cfloop array="#item[1].XmlChildren#" index="node">
                <cfset stcTip[node.XmlName]= REReplace(node.XmlText,'</?.+?>','','all')>
            </cfloop>
            <cffile action="write" file="#this.rootPath#content/tip.json" charset="utf-8" output="#SerializeJSON(stcTip)#" nameconflict="overwrite">
            <cfcatch type="any">
            	<cfset stcTip=StructNew()>
            </cfcatch>
        </cftry>
        <cfreturn stcTip>
	</cffunction>
    
	<cffunction name="getQuickTips" access="public" output="no" returntype="query">
        <cffile action="read" file="#this.rootPath#content/quick_tips.txt" variable="linkCSV" charset="utf-8" />
        <cfreturn csvToQuery(linkCSV,Chr(9))>
	</cffunction>
    
	<cffunction name="getVideoPlaylist" access="public" output="no" returntype="query">
    	<cfargument name="playlist_id" required="yes" type="string">
        <cfset filename="#this.rootPath#content/playlist_#playlist_id#.txt">
        <cfset delim=Chr(9)>
        <cfset lineDelim=Chr(13)&Chr(10)>
		<!--- <cfif FileExists(filename)>
            <cfset qPlaylist=csvToQuery(FileRead(filename),delim)>
        <cfelse> --->
			<cfset qPlaylist=QueryNew('title,video_id')>
            <cfhttp url="http://gdata.youtube.com/feeds/api/playlists/#playlist_id#?v=2&alt=rss" />
            <cfset feed=XMLParse(cfhttp.FileContent)>
            <cfset item=XMLSearch(feed,'//item')>
            <cfloop array="#item#" index="node">
                <cfset QueryAddRow(qPlaylist)>
                <cfset QuerySetCell(qPlaylist,'title',node.title.XmlText)>
                <cfset QuerySetCell(qPlaylist,'video_id',node['media:group']['yt:videoid'].XmlText)>
            </cfloop>
            <cfset playlistCSV="title#delim#video_id">
           	<cfloop query="qPlaylist">
            	<cfset playlistCSV&= lineDelim & title & delim & video_id>
            </cfloop>
            <cffile action="write" file="#filename#" charset="utf-8" output="#playlistCSV#" nameconflict="overwrite">
        <!--- </cfif> --->
        <cfreturn qPlaylist>
	</cffunction>
    
	<cffunction name="getAllTipsOfTheDay" access="public" output="no" returntype="struct">
		<cfset stcTip=StructNew()>
        <cfset header="">
        <cfset delim=chr(9)>
        <cfset lineDelim=Chr(13)&Chr(10)>
        <cfset data=ArrayNew(1)>
        <cfset map=StructNew()>
        <cfset default="">
        <cfhttp url="http://www.eatright.org/RSS/feed.aspx?feed=tips" />
        <cfset feed=XMLParse(cfhttp.FileContent)>
        <cfset items=XMLSearch(feed,'//item')>
        <cfloop array="#items[1].XmlChildren#" index="node">
            <cfif NOT StructKeyExists(map,node.XmlName)>
                <cfset header=ListAppend(header,node.XmlName,delim)>
                <cfset default=ListAppend(default,'*')>
                <cfset map[node.XmlName]=ListLen(header,delim)>
            </cfif>
        </cfloop>
        <cfset ArrayAppend(data,header)>
        <cfloop array="#items#" index="item">
        	<cfset row=ListToArray(default)>
            <cfloop array="#item.XmlChildren#" index="node">
                <cfif StructKeyExists(map,node.XmlName)>
                	<cfset text=REReplace(node.XmlText,'\s+',' ','all')>
                    <cfif Find(delim, text) neq 0>
                    	<cfset text='"#text#"'>
                    </cfif>
					<cfset row[map[node.XmlName]]=text>
                </cfif>
            </cfloop>
            <cfif NOT ArrayIsEmpty(row)>
	            <cfset ArrayAppend(data,ArrayToList(row,delim))>
            </cfif>
        </cfloop>
        <cffile action="write" file="#this.rootPath#content/tips.txt.xls" output="#ArrayToList(data, lineDelim)#" nameconflict="overwrite" charset="utf-8">
        <cfreturn stcTip>
	</cffunction>
	<!--- 
		function: getDefaulTipOfTheDay
		in: 
		out: struct
		notes: Utility function
	 --->
	<cffunction name="getDefaultTipOfTheDay" access="public" output="no" returntype="struct">
		<cftry>
        	<cffile action="read" file="#this.rootPath#content/tip.json" charset="utf-8" variable="jsonTip">
            <cfreturn DeserializeJSON(jsonTip)>
            <cfcatch type="any">
				<cfscript>
                    var stcTip=StructNew();
                    stcTip.title='No tip today';
                    stcTip.link = '##';
                    stcTip.description="This default tip will only be shown if the RSS feed fails and there is no previous tip saved. This is unlikely to happen, but who knows?";
                    stcTip.pubDate=GetHttpTimeString(CreateDate(2000,1,1));
                    return stcTip;
                </cfscript>
            </cfcatch>
        </cftry>
	</cffunction>
	<cffunction name="getSelectStruct" access="public" output="no" returntype="struct">
		<cfset select=StructNew()>
        <cfset select[0 eq 0]=' selected="selected" '>
        <cfset select[0 eq 1]=''>
        <cfreturn select>
	</cffunction>
	<cffunction name="getJSON" access="public" output="no" returntype="string" hint="Returns JSON string for app">
    	<cfset result=ArrayNew(1)>
        <cfloop collection="#arguments#" item="jsvar">
        	<cfif IsQuery(arguments[jsvar])>
				<cfset ArrayAppend(result,"#jsvar#=_q(#SerializeJSON(arguments[jsvar])#)")>
            <cfelse>
				<cfset ArrayAppend(result,"#jsvar#=#SerializeJSON(arguments[jsvar])#")>
            </cfif>
        </cfloop>
        <cfreturn ArrayToList(result,';')>
    </cffunction>
</cfcomponent>
