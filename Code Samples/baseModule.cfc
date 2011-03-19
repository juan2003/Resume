<cfcomponent displayname="Base Module Component" hint="Extend this component to create modules">
    <cffunction name="init" access="public" returntype="void" hint="This parses user preferences to make them available within the object">
    	<cfargument name="userPrefs" type="struct" required="yes">
        <cfset this.user=arguments.userPrefs>
    </cffunction>
	<cffunction name="getModuleContent" access="public" returntype="any" output="no">
        <cfscript>
			var metadata=GetMetadata(this);
			var content=structNew();
			var x=1;
			var order=StructNew();
			var key='';
			var last ='';
			var newOrder = ArrayNew(1);
			//Render tabs
			if( StructKeyExists(metadata,'functions') ){
				for(x=1; x<=arrayLen(metadata.functions); x++) {
					if( Left(metadata.functions[x].name,3) == 'tab' ) {
						key = IIf(StructKeyExists(metadata.functions[x],'displayname'),'metadata.functions[x].displayname','unCamel(Right(metadata.functions[x].name,Len(metadata.functions[x].name)-3))');
						addTab(content,key,metadata.functions[x].name);
						//Add taborder
						if( StructKeyExists(metadata.functions[x],'order') ){
							order[metadata.functions[x].order]=key;
						}
					}
				}
				//Replace tabOrder array
				if ( !StructIsEmpty(order) ){
					if( StructKeyExists(order,'last') ){
						last = order.last;
						StructDelete(order,'last');
					}
					if( StructKeyExists(order,'first') && order.first != '' ){
						ArrayAppend(newOrder,order.first);
						StructDelete(order,'first');
					}
					key = StructKeyArray(order);
					ArraySort(key,'numeric');
					for( x=1; x<=ArrayLen(key); x++) {
						ArrayAppend(newOrder,order[key[x]]);
					}
					if( last != '' ) {
						ArrayAppend(newOrder,last);
					}
					content.tabOrder = newOrder;
				}
			}
			return IIf(StructKeyExists(content,'tabOrder') AND ArrayLen(content.tabOrder)==1,'content[content.tabOrder[1]]','content');
		</cfscript>
	</cffunction>
	<cffunction name="getDefaultTitle" access="public" returntype="string" output="no">
        <cfset var metadata=GetMetadata(this)>
        <cfset defaultTitle=IIf(StructKeyExists(metadata,'displayname'),'metadata.displayname','metadata.name')>
        <cfreturn defaultTitle>
    </cffunction>
    <!--- Options --->
	<cffunction name="getOptions" access="public" returntype="struct" output="no">
        <cfset options=structNew()>
        <cfreturn options>
    </cffunction>
    <cffunction name="addTab" output="false" hint="This function adds a tab to a modules content">
        <cfargument name="content" type="struct" required="yes" />
        <cfargument name="tab" type="string" required="yes" />
        <cfargument name="method" type="string" required="yes" />
        <cfsavecontent variable="html">
	        <cfinvoke method="#arguments.method#" />
        </cfsavecontent>
        <cfscript>
            if ( !structKeyExists(content,'tabOrder') ){
                content.tabOrder = arrayNew(1);
            }
            structInsert(content,tab,html,true);
            if( ListFindNoCase(ArrayToList(content.tabOrder),tab) == 0 ){
				arrayAppend(content.tabOrder,tab);
			}
        </cfscript>
	</cffunction>
    <cffunction name="unCamel" returntype="string" access="private">
    	<cfargument name="str" required="yes" type="string">
        <cfreturn REReplace(str, '([A-Z])', ' \1', 'ALL')>
    </cffunction>
    <cffunction name="titleCase" returntype="string" access="private">
        <cfargument name="str" required="yes" type="string">
        <cfscript>
            var words=ListToArray(str,' ');
            var title=ArrayNew(1);
            var word = '';
            var x=1;
            for(x=1; x<=ArrayLen(words); x++) {
                word = LCase(words[x]);
                if( Len(word) > 3 ){
                    word = UCase(Left(word,1)) & Right(word,Len(word)-1);
                }
                ArrayAppend(title, word);
            }
            return ArrayToList(title,' ');
        </cfscript>
    </cffunction>
</cfcomponent>