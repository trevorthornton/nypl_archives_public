

#make it an array
window.Archives.templates['singleComponent'] = new Array();


#
# The Default Layout
#

window.Archives.templates['singleComponent'][1] = """
       
  <% 

    if (!renderRow){
      var renderRow = false;
    }

    var hasOrigination = (model.origination) ? true : false;
    var hasContainer = (model.container) ? true : false;
    var hasDigitalAsset = (model.image) ? true : false;    
    var hasUnitid= (model.unitid) ? true : false;  
    var hasDocuments = (model.documents) ? true : false;
    var hasExternalResources = (model.external_resources) ? true : false;


    var title = (model.title) ? model.title : "";
    var dateStatement = (model.date_statement) ? model.date_statement : "";
    var extentStatement = (model.extent_statement) ? model.extent_statement : "";
    var abstract = (model.abstract) ? model.abstract : ""; 
    var origination = (model.origination) ? model.origination : ""; 
    
    var physdescNote = (model.physdesc_note) ? model.physdesc_note : ""; 
    
    var bioghist = (model.bioghist) ? model.bioghist : ""; 
    var scopecontent = (model.scopecontent) ? model.scopecontent : ""; 
    var note = (model.note) ? model.note : ""; 
    var physloc  = (model.physloc ) ? model.physloc  : ""; 
    var arrangement = (model.arrangement) ? model.arrangement : ""; 
    var accessrestrict = (model.accessrestrict) ? model.accessrestrict : ""; 
    var arrangement = (model.arrangement) ? model.arrangement : ""; 
    var appraisal = (model.appraisal) ? model.appraisal : ""; 
    var langmaterial = (model.langmaterial) ? model.langmaterial : ""; 
    var odd = (model.odd) ? model.odd : ""; 
    var bibliography = (model.bibliography) ? model.bibliography : ""; 
    
    var controlaccess = (model.controlaccess) ? model.controlaccess : "";
    
    
    if (model.controlaccess){
      
      var displayControlaccess = '';
      var displayControlaccessNames = '';
      var displayControlaccessTerms = '';
      
      var controlaccessNames = _.pick(model.controlaccess,'name');
      var controlaccessTerms = _.omit(model.controlaccess,'name');
      
      if (!(_.isEmpty(controlaccessNames))) {
        _.each(controlaccessNames, function(s, sIndex) { 

            _.each(s, function(t, tIndex) { 
              var extra = '';
              if (t.role){
                extra = "&nbsp(" + t.role + ")";
              }

              separator = "; &nbsp;";
            
              displayControlaccessNames += '<a title="' + sIndex + '/' + t.type +'" href="/controlaccess/' + t.id + '?term=' + encodeURIComponent(t.term) +  '">' + t.term  + extra + '</a>' + separator;

            });
            
            displayControlaccessNames = displayControlaccessNames.replace(/(\; \&nbsp\;)$/,'');
            
        });
      };
      
      
      if (!(_.isEmpty(controlaccessTerms))) {
        _.each(controlaccessTerms, function(s, sIndex) { 

            _.each(s, function(t, tIndex) {
              separator = "; &nbsp;";
              displayControlaccessTerms += '<a title="' + sIndex + '/' + t.type +'" href="/controlaccess/' + t.id + '?term=' + encodeURIComponent(t.term) +  '">' + t.term  + '</a>' + separator;

            });
            
            displayControlaccessTerms = displayControlaccessTerms.replace(/(\; \&nbsp\;)$/,'');
        });
      };
      
      
    }

    var useDateAsTitle = (!model.title) ? 'style="color:#3f3a34"' : '';

    var displayContainer = '';
    var useSmallContainerFont = '';

    if (!hasContainer && hasUnitid){
        _.each(model.unitid, function(aUnit) { 
          if (typeof aUnit.type !== 'undefined'){
            if (aUnit.type !== "local_mss" && aUnit.type !== "local_barcode" &&  aUnit.type !== null){ 
              if (aUnit.value){
                displayContainer = displayContainer + aUnit.value;
              }              
            }

            if (aUnit.type === null){
              if (aUnit.value){

                if (isNaN(parseInt(aUnit.value))){                  
                  displayContainer = displayContainer + aUnit.value;
                }else if (parseInt(aUnit.value) < 20000){
                  displayContainer = displayContainer + aUnit.value;
                }
              }   
            } 

          }else{

            if (aUnit.value){

                if (isNaN(parseInt(aUnit.value))){                  
                  displayContainer = displayContainer + aUnit.value;
                }else if (parseInt(aUnit.value) < 20000){
                  displayContainer = displayContainer + aUnit.value;
                }

            }


          }
        });

     }

     
      if (appraisal !== ''){
        var displayAppraisal = '';
        _.each(appraisal, function(a) {
          if (a.value){
            displayAppraisal += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (langmaterial !== ''){
        var displayLangmaterial = '';
        _.each(langmaterial, function(a) {
          if (a.value){
            displayLangmaterial += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (odd !== ''){
        var displayOdd = '';
        _.each(odd, function(a) {
          if (a.value){
            displayOdd += Archives.data.removeHtmlTags(a.value);
          }
        });
     }

     
     if (accessrestrict !== ''){
        var displayAccessrestrict = '';
        _.each(accessrestrict, function(a) {
          if (a.value){
            displayAccessrestrict += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (arrangement !== ''){
        var displayArrangement = '';
        _.each(arrangement, function(a) {
          if (a.value){
            displayArrangement += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
      if (note !== ''){
        var displayNote = '';
        _.each(note, function(a) {
          if (a.value){
            displayNote += Archives.data.removeHtmlTags(a.value);
          }
        });
     }

     if (bioghist !== ''){
        var displayBioghist = '';
        _.each(bioghist, function(a) {
          if (a.value){
            displayBioghist += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (physdescNote !== ''){
        var displayPhysdescNote = '';
        _.each(physdescNote, function(a) {
          if (a.value){
            displayPhysdescNote += Archives.data.removeHtmlTags(a.value);
          }
        });
     }

     if (abstract !== ''){
        var displayAbstract = '';
        _.each(abstract, function(a) {
          if (a.value){
            displayAbstract += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (physloc !== ''){
        var displayPhysloc = '';
        _.each(physloc, function(a) {
          if (a.value){
            displayPhysloc += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (bibliography !== ''){
        var displayBibliography = '';
        _.each(bibliography, function(a) {
          if (a.value){
            displayBibliography += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (origination !== ''){
        var displayOrigination = '';
        _.each(origination, function(a,index) {
          if (a.value){
            displayOrigination += Archives.data.removeHtmlTags(a.value);
            if (index !== (origination.length - 1)) {
              displayOrigination += "; ";
            }
          }
        });
     }

     if (scopecontent !== ''){
        var displayScopecontent = '';
        _.each(scopecontent, function(a) {
          if (a.value){
            displayScopecontent += Archives.data.removeHtmlTags(a.value);

            
          }
        });
     }



    if (hasContainer){      

      

      _.each(model.container, function(container) {

          var displayContainerType = '';
          var displayContainerValue = '';
          var displayContainerTypeFull = '';


          if (container.type){
            displayContainerType = container.type[0] + '.&nbsp;';
            displayContainerTypeFull = container.type;

            if (container.type == 'internal_collection_link'){

              displayContainerType = '<a href="' + container.value + '">Go To Collection <i class="icon-share-alt"></i></a>';

            }

            if (container.type == 'oversize_folder'){

              displayContainerType = 'of' + '.&nbsp;';

            }


          }

          if (container.value){
            displayContainerValue = container.value;

            if (container.type == 'internal_collection_link'){
              displayContainerValue = '';
            }
          }

          if (displayContainerValue.length>35)
            useSmallContainerFont = ' container-desc-small';


          displayContainer += '&nbsp;<span class="container-abrv" title="' + displayContainerTypeFull + '">' + displayContainerType + '</span>' + displayContainerValue + '';


      });

    }

    if (hasDigitalAsset)
      displayContainer = '<a href="#" class="asset-link">' + displayContainer + '&nbsp;<i class="icon-film">&nbsp;</i></a>';


  %>


  <% if (renderRow) { 

    var margin = (model.level_text === 'series' || model.level_text === 'subseries' ) ? ' margin-' + model.level_text : '';

  %>
            

    <div id="c<%=model.id%>" class="collection-detailed-row<%=margin%>">


  <% } %>


  <div class="container-desc indent-width-<%=model.level_num%><%=  (model.level_text === 'series' ) ? ' container-desc-series'  : ''%><%=useSmallContainerFont%>">



      <% if (model.level_text === 'subseries' && displayContainer !== ''){ %>

        <div class="<%=(hasDigitalAsset) ? ' asset-link-container' : ''%>">
          <%=displayContainer%>
        </div>


      <% }else if (model.level_text === 'series' && displayContainer !== ''){ %>


      <% }else{ %>

        <div class="<%=(hasDigitalAsset) ? ' asset-link-container' : ''%>">
          <%=displayContainer%>
        </div>

      <% } %>




  </div>



  <div class="component-content remainder-width-<%=model.level_num%><%=  (model.level_text === 'series' ) ? ' content-series'  : ''%>">

    <% if (hasOrigination){ %>
   
      <div class="origination"><%=displayOrigination%></div>

    <% } %>

    <div class="title <%=  (model.level_text !== '' ) ? ' ' + model.level_text : ''%>"><%=title%></div>

    <% if (model.level_text === 'series' && displayContainer !== ''){ %>

      <div class="series-container<%=(hasDigitalAsset) ? ' asset-link-container' : ''%>">&nbsp;(<%= displayContainer %>)</div>

    <% } %>



    <% if (dateStatement !== '') { %>
      <div <%=useDateAsTitle%> class="date" >&nbsp;<%= dateStatement %></div>
    <% } %>
    
    <% if (extentStatement !== '') { %>
      <div class="extent element-content-block"><%= extentStatement %></div>
    <% } %>
    
    <% if (physdescNote !== '') { %>
      <div class="physdesc-note element-content-block"><%= displayPhysdescNote %></div>
    <% } %>      

    <% if (abstract !== '') { %>
      <div class="abstract element-content-block"><%= displayAbstract %></div>
    <% } %>

    <% if (bioghist !== '') { %>
      <div class="bioghist element-content-block"><%= displayBioghist %></div>
    <% } %>
    
    <% if (scopecontent !== '') { %>
      <div class="scopecontent element-content-block"><%= displayScopecontent %></div>
    <% } %>
    
    <% if (note !== '') { %>
      <div class="note element-content-block"><%= displayNote %></div>
    <% } %>

    <% if (arrangement !== '') { %>
      <div class="arrangement element-content-block"><%= displayArrangement %></div>
    <% } %>

    <% if (physloc !== '') { %>
      <div class="physloc element-content-block">Location: <%= displayPhysloc %></div>
    <% } %>

    <% if (accessrestrict !== '') { %>
      <div class="accessrestrict element-content-block"><%= displayAccessrestrict %></div>
    <% } %>

    <% if (appraisal !== '') { %>
      <div class="appraisal element-content-block"><%= displayAppraisal %></div>
    <% } %>

    <% if (langmaterial !== '') { %>
      <div class="langmaterial element-content-block"><%= displayLangmaterial %></div>
    <% } %>
    
    <% if (odd !== '') { %>
      <div class="odd element-content-block"><%= displayOdd %></div>
    <% } %>
    
    <% if (bibliography !== '') { %>
      <div class="bibliography element-content-block"><%= displayBibliography %></div>
    <% } %>


    <% if (hasDocuments) { %>

      <% _.each(model.documents,function(e,i){ %>

          <div class="attached-document element-content-block"><a href="/uploads/documents/<%=e.document_type.replace(/ /g,'_')%>/<%=e.file%>"><i class="icon-file"></i><%=e.title%></a> : <%=e.description%></div>

      <% }); %>
        
    <% } %>

    <% if (hasExternalResources) { %>

      <% _.each(model.external_resources,function(e,i){ %>

          <div class="attached-external-resource element-content-block"><a href="<%=e.url%>"><i class="icon-globe"></i> <%=e.title%></a>: <%=e.description%></div>

      <% }); %>
        
    <% } %>




    <% if (controlaccess !== '') { %>
        
        <% if (displayControlaccessNames !== '') { %>
          <div class="names element-content-block">
            <%=displayControlaccessNames%>
          </div>
        <% } %>
        
        <% if (displayControlaccessTerms !== '') { %>
          <div class="terms element-content-block">
            Terms: <%=displayControlaccessTerms%>
          </div>
        <% } %>
        
    <% } %>


  </div>


  <% if (renderRow) { %>

    </div>

  <% } %>


  """













#
#
#
#
#
#
#
#
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#
#
#
#
#
#
#
#









#
# Special Berg(?) Layout
#

window.Archives.templates['singleComponent'][2] = """
       
  <% 
    
    var multipleParagraphs = function(string) {
      return (string.match(/\<p\>/).length > 1) ? true : false
    };
    
    var stripSingleParagraph = function(string) {
      if (multipleParagraphs(string) == false) {
        string = string.replace(/\<[\/]?p\>/g,'');
      }
      return string;
    };
    
    if (!renderRow){
      var renderRow = false;
    }

    var hasOrigination = (model.origination) ? true : false;
    var hasContainer = (model.container) ? true : false;
    var hasDigitalAsset = (model.image) ? true : false;    
    var hasUnitid= (model.unitid) ? true : false;  

    var title = (model.title) ? model.title : "";
    var dateStatement = (model.date_statement) ? model.date_statement : "";
    var extentStatement = (model.extent_statement) ? model.extent_statement : "";
    var abstract = (model.abstract) ? model.abstract : ""; 
    var origination = (model.origination) ? model.origination : ""; 
    var originationPlace = (model.origination_place) ? model.origination_place : "";
    var hasDocuments = (model.documents) ? true : false;
    var hasExternalResources = (model.external_resources) ? true : false;

    var physdescNote = (model.physdesc_note) ? model.physdesc_note : ""; 
    var bioghist = (model.bioghist) ? model.bioghist : ""; 
    var scopecontent = (model.scopecontent) ? model.scopecontent : ""; 
    var note = (model.note) ? model.note : ""; 
    var physloc  = (model.physloc ) ? model.physloc  : ""; 
    var arrangement = (model.arrangement) ? model.arrangement : ""; 
    var accessrestrict = (model.accessrestrict) ? model.accessrestrict : ""; 
    var arrangement = (model.arrangement) ? model.arrangement : ""; 
    var appraisal = (model.appraisal) ? model.appraisal : ""; 
    var langmaterial = (model.langmaterial) ? model.langmaterial : ""; 
    var odd = (model.odd) ? model.odd : ""; 
    var bibliography = (model.bibliography) ? model.bibliography : ""; 
    var custodhist = (model.custodhist) ? model.custodhist : ""; 
    
    var controlaccess = (model.controlaccess) ? model.controlaccess : "";
    var originationPlace = (model.origination_place) ? model.origination_place : "";
    
    if (model.controlaccess){
      
      var displayControlaccess = '';
      var displayControlaccessNames = '';
      var displayControlaccessForms = '';
      var displayControlaccessSubjects = '';
      
      var controlaccessNames = _.pick(model.controlaccess,'name');
      var controlaccessForms = _.pick(model.controlaccess,'genreform');
      var controlaccessSubjects = _.omit(model.controlaccess,['name','genreform']);
      
      if (!(_.isEmpty(controlaccessNames))) {
        _.each(controlaccessNames, function(s, sIndex) { 

            _.each(s, function(t, tIndex) { 
              var extra = '';
              if (t.role){
                extra = "&nbsp(" + t.role + ")";
              }

              separator = "; &nbsp;";
            
              displayControlaccessNames += '<a title="' + sIndex + '/' + t.type +'" href="/controlaccess/' + t.id + '?term=' + encodeURIComponent(t.term) +  '">' + t.term  + extra + '</a>' + separator;

            });
            
            displayControlaccessNames = displayControlaccessNames.replace(/(\; \&nbsp\;)$/,'');
            
        });
      };
      
      
      if (!(_.isEmpty(controlaccessSubjects))) {
        _.each(controlaccessSubjects, function(s, sIndex) { 

            _.each(s, function(t, tIndex) {
              separator = "; &nbsp;";
              displayControlaccessSubjects += '<a title="' + sIndex + '/' + t.type +'" href="/controlaccess/' + t.id + '?term=' + encodeURIComponent(t.term) +  '">' + t.term  + '</a>' + separator;

            });
            
            displayControlaccessSubjects = displayControlaccessSubjects.replace(/(\; \&nbsp\;)$/,'');
        });
      };
      
      if (!(_.isEmpty(controlaccessForms))) {
        _.each(controlaccessForms, function(s, sIndex) { 

            _.each(s, function(t, tIndex) {
              separator = "; &nbsp;";
              displayControlaccessForms += '<a title="' + sIndex + '/' + t.type +'" href="/controlaccess/' + t.id + '?term=' + encodeURIComponent(t.term) +  '">' + t.term  + '</a>' + separator;

            });
            
            displayControlaccessForms = displayControlaccessForms.replace(/(\; \&nbsp\;)$/,'');
        });
      };
      
    }

    var useDateAsTitle = (!model.title) ? 'style="color:#3f3a34"' : '';

    var displayContainer = '';
    var useSmallContainerFont = '';

    if (!hasContainer && hasUnitid){
        _.each(model.unitid, function(aUnit) { 
          if (typeof aUnit.type !== 'undefined'){
            if (aUnit.type !== "local_mss" && aUnit.type !== "local_barcode" &&  aUnit.type !== null){ 
              if (aUnit.value){
                displayContainer = displayContainer + aUnit.value;
              }              
            }

            if (aUnit.type === null){
              if (aUnit.value){

                if (isNaN(parseInt(aUnit.value))){                  
                  displayContainer = displayContainer + aUnit.value;
                }else if (parseInt(aUnit.value) < 20000){
                  displayContainer = displayContainer + aUnit.value;
                }
              }   
            } 

          }else{

            if (aUnit.value){

                if (isNaN(parseInt(aUnit.value))){                  
                  displayContainer = displayContainer + aUnit.value;
                }else if (parseInt(aUnit.value) < 20000){
                  displayContainer = displayContainer + aUnit.value;
                }

            }


          }
        });

     }

     
      if (appraisal !== ''){
        var displayAppraisal = '';
        _.each(appraisal, function(a) {
          if (a.value){
            displayAppraisal += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (langmaterial !== ''){
        var displayLangmaterial = '';
        _.each(langmaterial, function(a) {
          if (a.value){
            displayLangmaterial += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (odd !== ''){
        var displayOdd = '';
        _.each(odd, function(a) {
          if (a.value){
            displayOdd += Archives.data.removeHtmlTags(a.value);
          }
        });
     }

     
     if (accessrestrict !== ''){
        var displayAccessrestrict = '';
        _.each(accessrestrict, function(a) {
          if (a.value){
            displayAccessrestrict += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (arrangement !== ''){
        var displayArrangement = '';
        _.each(arrangement, function(a) {
          if (a.value){
            displayArrangement += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (note !== ''){
        var displayNote = '';
        _.each(note, function(a) {
          if (a.value){
            displayNote += Archives.data.removeHtmlTags(a.value);
          }
        });
        displayNote = stripSingleParagraph(displayNote);
     }

     if (bioghist !== ''){
        var displayBioghist = '';
        _.each(bioghist, function(a) {
          if (a.value){
            displayBioghist += Archives.data.removeHtmlTags(a.value);
          }
        });
     }

     if (abstract !== ''){
        var displayAbstract = '';
        _.each(abstract, function(a) {
          if (a.value){
            displayAbstract += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (physloc !== ''){
        var displayPhysloc = '';
        _.each(physloc, function(a) {
          if (a.value){
            displayPhysloc += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (originationPlace !== ''){
        var displayOriginationPlace = '';
        _.each(originationPlace, function(a, index) {
          if (a.term){
            displayOriginationPlace += Archives.data.removeHtmlTags(a.term);
            if (index !== (originationPlace.length - 1)) {
              displayOriginationPlace += "; ";
            }
          }
        });
     }
     
     
     if (physdescNote !== ''){
        var displayPhysdescNote = '';
        _.each(physdescNote, function(a) {
          if (a.value){
            displayPhysdescNote += Archives.data.removeHtmlTags(a.value);
          }
        });
        displayPhysdescNote = stripSingleParagraph(displayPhysdescNote);
     }
     
     
     if (bibliography !== ''){
        var displayBibliography = '';
        _.each(bibliography, function(a) {
          if (a.value){
            displayBibliography += Archives.data.removeHtmlTags(a.value);
          }
        });
     }
     
     if (custodhist !== ''){
        var displayCustodhist = '';
        _.each(custodhist, function(a) {
          if (a.value){
            displayCustodhist += Archives.data.removeHtmlTags(a.value);
          }
        });
        displayCustodhist = stripSingleParagraph(displayCustodhist);
     }
     
     if (origination !== ''){
        var displayOrigination = '';
        _.each(origination, function(a, index) {
          if (a.value){
            displayOrigination += Archives.data.removeHtmlTags(a.value);
            if (index !== (origination.length - 1)) {
              displayOrigination += "; ";
            }
          }
        });
     }

     if (scopecontent !== ''){
        var displayScopecontent = '';
        _.each(scopecontent, function(a) {
          if (a.value){
            displayScopecontent += Archives.data.removeHtmlTags(a.value);            
          }
        });
     }



    if (hasContainer){      

      

      _.each(model.container, function(container) {

          var displayContainerType = '';
          var displayContainerValue = '';
          var displayContainerTypeFull = '';


          if (container.type){
            displayContainerType = container.type[0] + '.&nbsp;';
            displayContainerTypeFull = container.type;

            if (container.type == 'internal_collection_link'){

              displayContainerType = '<a href="' + container.value + '">Go To Collection <i class="icon-share-alt"></i></a>';

            }

            if (container.type == 'oversize_folder'){

              displayContainerType = 'of' + '.&nbsp;';

            }


          }

          if (container.value){
            displayContainerValue = container.value;

            if (container.type == 'internal_collection_link'){
              displayContainerValue = '';
            }
          }

          if (displayContainerValue.length>35)
            useSmallContainerFont = ' container-desc-small';


          displayContainer += '&nbsp;<span class="container-abrv" title="' + displayContainerTypeFull + '">' + displayContainerType + '</span>' + displayContainerValue + '';


      });

    }

    if (hasDigitalAsset)
      displayContainer = '<a href="#" class="asset-link">' + displayContainer + '&nbsp;<i class="icon-film">&nbsp;</i></a>';


  %>


  <% if (renderRow) { 

    var margin = (model.level_text === 'series' || model.level_text === 'subseries' ) ? ' margin-' + model.level_text : '';

  %>
            

    <div id="c<%=model.id%>" class="collection-detailed-row<%=margin%> template-2-row">


  <% } %>


  <div class="container-desc indent-width-<%=model.level_num%><%=  (model.level_text === 'series' ) ? ' container-desc-series'  : ''%><%=useSmallContainerFont%>">



      <% if (model.level_text === 'subseries' && displayContainer !== ''){ %>

        <div class="<%=(hasDigitalAsset) ? ' asset-link-container' : ''%>">
          <%=displayContainer%>
        </div>


      <% }else if (model.level_text === 'series' && displayContainer !== ''){ %>


      <% }else{ %>

        <div class="<%=(hasDigitalAsset) ? ' asset-link-container' : ''%>">
          <%=displayContainer%>
        </div>

      <% } %>




  </div>



  <div class="component-content remainder-width-<%=model.level_num%><%=  (model.level_text === 'series' ) ? ' content-series'  : ''%>">

    <% if (hasOrigination){ %>
   
      <div class="origination"><%=displayOrigination%></div>

    <% } %>
    
    
    
      <div class="title <%=  (model.level_text !== '' ) ? ' ' + model.level_text : ''%>"><%=title%></div>
    
        
      <% if (model.level_text === 'series' && displayContainer !== ''){ %>
        <div class="series-container<%=(hasDigitalAsset) ? ' asset-link-container' : ''%>">&nbsp;(<%= displayContainer %>)</div>
      <% } %>
    
    
      <% if ((dateStatement !== '') && (useDateAsTitle !== '')) { %>
        <div <%=useDateAsTitle%> class="date" >&nbsp;<%= dateStatement %></div>
      <% } %>
    
    
    
    <% if ((dateStatement !== '') && (useDateAsTitle == '')) { %>
      <div class="element-content-block date" >
        <span class="label">Date:</span>
        <%= dateStatement %>
      </div>
    <% } %>
    
    
    <% if (extentStatement !== '') { %>
      <div class="element-content-block extent">
        <span class="label">Extent:</span>
        <%= extentStatement %>
      </div>
    <% } %>
    
    <% if (physdescNote !== '') { %>
      <div class="physdesc_note element-content-block">
        <span class="label">Physical description:</span>
        <%= displayPhysdescNote %>
      </div>
    <% } %>
    
    <% if (abstract !== '') { %>
      <div class="abstract element-content-block">
        <span class="label">Description:</span>
        <%= displayAbstract %>
      </div>
    <% } %>

    <% if (bioghist !== '') { %>
      <div class="bioghist element-content-block">
        <span class="label">Biographical/historical note:</span>
        <%= displayBioghist %>
      </div>
    <% } %>
    
    
    
    <% if (scopecontent !== '') { %>
      <div class="scopecontent element-content-block">
        <span class="label">Scope/content not:</span>
        <%= displayScopecontent %>
      </div>
    <% } %>

    <% if (note !== '') { %>
      <div class="note element-content-block">
        <span class="label">Note:</span>
        <%= displayNote %>
      </div>
    <% } %>
    
    
    <% if ((controlaccess !== '') && (displayControlaccessNames !== '')) { %>
      <div class="names element-content-block">
        <span class="label">Associated names:</span>
        <%=displayControlaccessNames%>
      </div>
    <% } %>
    
    
    <% if (arrangement !== '') { %>
      <div class="arrangement element-content-block">
        <span class="label">Arrangement:</span>
        <%= displayArrangement %>
      </div>
    <% } %>

    <% if (accessrestrict !== '') { %>
      <div class="accessrestrict element-content-block">
        <span class="label">Access restrictions:</span>
        <%= displayAccessrestrict %>
      </div>
    <% } %>

    <% if (appraisal !== '') { %>
      <div class="appraisal element-content-block"><%= displayAppraisal %></div>
    <% } %>

    <% if (langmaterial !== '') { %>
      <div class="langmaterial element-content-block">
        <span class="label">Language of materials:</span>
        <%= displayLangmaterial %>
      </div>
    <% } %>
    
    <% if (odd !== '') { %>
      <div class="odd element-content-block"><%= displayOdd %></div>
    <% } %>
    
    <% if (bibliography !== '') { %>
      <div class="bibliography element-content-block">
        <span class="label">Publication/citation:</span>
        <%= displayBibliography %>
      </div>
    <% } %>
    
    
    <% if ((controlaccess !== '') && (displayControlaccessSubjects !== '')) { %>
      <div class="terms element-content-block">
        <span class="label">Subject:</span>
        <%=displayControlaccessSubjects%>
      </div>
    <% } %>
    
    
    <% if ((controlaccess !== '') && (displayControlaccessForms !== '')) { %>
      <div class="terms element-content-block">
        <span class="label">Form/genre:</span>
        <%=displayControlaccessForms%>
      </div>
    <% } %>
    
    
    <% if (originationPlace !== '') { %>
      <div class="origination_place element-content-block">
        <span class="label">Place of origin:</span>
        <%= displayOriginationPlace %>
      </div>
    <% } %>
    
    <% if (custodhist !== '') { %>
      <div class="note element-content-block">
        <span class="label">Provenance:</span>
        <%= displayCustodhist %>
      </div>
    <% } %>
    
    <% if (physloc !== '') { %>
      <div class="physloc element-content-block">
        <span class="label">Location:</span>
        <%= displayPhysloc %>
      </div>
    <% } %>



    <% if (hasDocuments) { %>

      <% _.each(model.documents,function(e,i){ %>
          <div class="attached-document element-content-block">

            <a href="/uploads/documents/<%=e.document_type.replace(/ /g,'_')%>/<%=e.file%>"><i class="icon-file"></i><%=e.title%></a> : <%=e.description%>
          </div>
      <% }); %>
        
    <% } %>


    <% if (hasExternalResources) { %>

      <% _.each(model.external_resources,function(e,i){ %>
          <div class="attached-external-resource element-content-block">
            <a href="<%=e.url%>"><i class="icon-globe"></i> <%=e.title%></a>: <%=e.description%>
          </div>
      <% }); %>
        
    <% } %>
    


  </div>


  <% if (renderRow) { %>

    </div>

  <% } %>


  """


















#compress the template, just to conserve whitespace make it a little smaller
window.Archives.templates['singleComponent'][1] = window.Archives.templates['singleComponent'][1].replace(/\n/g, '').replace(/\s{2,}/g,'');
window.Archives.templates['singleComponent'][2] = window.Archives.templates['singleComponent'][2].replace(/\n/g, '').replace(/\s{2,}/g,'');



