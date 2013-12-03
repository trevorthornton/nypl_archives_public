



$(document).ready(function() {

    'use strict';

    var url = '/collections';

    var activeIds = [], ingestTimer = null, sucessfullyIngestedIds = [], doneIds = [];

    ingestUpdate();

    $('#fileupload').fileupload({
        url: url,
        dataType: 'json',
        done: function (e, data) {


            //if we are on the update page then kick off the ingest because we know all the info already
            if ($("#upload-update-button").length > 0){

                //ingest it
                $.get( "/collections/ingest/ingest_ead_from_interface", { filename: data.result.files[0].name, org_unit_id: $("#upload-update-button").data("orgid"), identifier_type : 'local_mss', identifier_value: $("#upload-update-button").data("id")})
                    .done(function( data ) {

                        if (data.error){
                            alert('There was a problem starting the ingest process: ' + data.message);
                        }else{
                            window.location = "/collections/new#status";
                        }


                    }

                );

            //otherwise build the ingest interface
            }else{

                $('button').prop('disabled', false);

                $(".none").remove();

                $.each(data.result.files, function (index, file) {

                    var tr = $("<tr>").addClass("transition");

                    tr.attr("id", file.name.replace(".xml",''));

                    tr.append($("<td>")
                        .addClass("filename")
                        .data("filename",file.name)
                        .text(file.name)
                    );


                    var select = $("<select>").attr("title","Select the divsion this collection belongs to.").addClass('org-unit-select').addClass("tool-tip");
                    var foundSelected = false;

                    $.each(orgs, function(index, org){


                        var o = $("<option>");


                        if (org.code.toLowerCase() === file.org.toLowerCase()){
                            o.attr("selected",true);
                            foundSelected = true;
                        }

                        o.val(org.id).text(org.code).attr("data-placement","right").attr("title",org.name_short).addClass("tool-tip");

                        select.append(o);



                    });

                    if (!foundSelected){
                        select.prepend($("<option>").val("-1").text("Select").attr("selected",foundSelected));
                    }else{
                        select.prepend($("<option>").val("-1").text("Select"));
                    }
                    




                    tr.append($("<td>")
                        .addClass("org-unit")
                        .append(select)
                    );

                    tr.append($("<td>")
                        .append($("<input>")
                            .addClass('mss-id')
                            .addClass('tool-tip')
                            .val(file.mssId)
                            .attr("title",'Enter the MSS ID of this collection. The system will try to pull it from the filename. It must be provied to move the collection into ingest.')
                            .attr("placeholder",'Enter MSS Id')                        
                            .attr("type",'text')
                        )
                    );
                    tr.append($("<td>")
                        .append($("<input>")
                            .addClass('bnumber')
                            .addClass('tool-tip')
                            .val('')
                            .attr("title",'Enter the catalog B-Number if available.')
                            .attr("placeholder",'B-Number')                        
                            .attr("type",'text')
                        )
                    );
                    tr.append($("<td>")

                        .append($("<button>")
                            .addClass('btn')
                            .addClass('btn-primary')
                            .addClass('btn-small')
                            .addClass('tool-tip')
                            .addClass('start-ingest-single')
                            .data('filename',file.name)
                            .attr("title",'Move this EAD files into the ingest queue.')
                            .text('✓')
                        )

                        .append($("<button>")
                            .addClass('btn')
                            .addClass('btn-danger')
                            .addClass('btn-small')
                            .addClass('remove-tmp-ead')
                            .data('filename',file.name)
                            .addClass('tool-tip')
                            .attr("title",'Delete this uploaded EAD file from the server.')
                            .text('X')
                        )

                    );

                    $("#ead-files-table").append(tr);


                });
                
                rebind();    

            }


            


        },
        error: function (e, data){

            console.log(e);

        },
        progressall: function (e, data) {

            var progress = parseInt(data.loaded / data.total * 100, 10);
            $('#progress .progress-bar').css(
                'width',
                progress + '%'
            );
        }
    });




    rebind();

    $("#upload-button,#upload-update-button").click(function(e){

        $("#fileupload").click();

        e.preventDefault();
        return false;

    });

    function rebind(){

            $(".tool-tip").tooltip();

            $(".remove-tmp-ead").unbind('click').click(function(){
                remove_tmp_ead($(this).data('filename'),$(this));
            });
            $(".start-ingest-single").unbind('click').click(function(){
                ingest_ead($(this).data('filename'),$(this));
            });

            $("#catalog-ingest-tr button").unbind('click').click(function(){
                ingest_bnumber($(this));
            });

            $("#ingest-all").unbind('click').click(function(){

                $("#ead-files-table .start-ingest-single").click();

            });

            $("#update-bnumber-button").unbind('click').click(function(){
                update_bnumber($(this).data("id"),$(this).data("org"),$(this).data("bnumber"));
            });


            $(".uuid-link").unbind('click').click(function(e){
                display_captures($(this).data('ids'));
                e.preventDefault();
                return false;
            });



    }

    function display_captures(ids){

        ids = ids.split('|');
        
        $("#uuid-attachments-display .thumbnails").empty();

        for (var x in ids){

        $("#uuid-attachments-display .thumbnails").append(

            $("<li>")
                .addClass('span1')
                .append(
                    $("<a>")
                    .addClass('thumbnail')
                    .append(
                        $("<img>")
                            .attr("src",'http://images.nypl.org/index.php?id=' + ids[x] + '&t=t')
                    )
                )


        );
        }

    }

    function update_bnumber (id, org, bnumber){


        //ingest it
        $.get( "/collections/ingest/ingest_bnumber_from_interface", { bnumber: bnumber, org_unit_id: org, identifier_type : 'local_mss', identifier_value: id})
            .done(function( data ) {

                if (data.error){
                    alert('There was a problem starting the ingest process: ' + data.message);
                }else{
                    window.location = "/collections/new#status";
                }
        })

    }

    function ingest_bnumber(dom){
    
        var bnumber = dom.parent().parent().find('.bnumber').val();
        var mmsId = dom.parent().parent().find('.mss-id').val();
        var org = dom.parent().parent().find('select').val();

        dom.parent().parent().find('.mss-id').css("border-color","");
        dom.parent().parent().find('.bnumber').css("border-color","");
        dom.parent().parent().find('select').css("border-color","");

        $(".catalog-ingest-error").text("");

        var regB = /(^b[0-9]*)/i;

        

        if (!regB.test(bnumber)){
            $(".catalog-ingest-error").text("That B-Number does not look right, should be 'b#######...'");
            dom.parent().parent().find('.bnumber').css("border-color","red");
            return false;
        }
        if (org == -1){
            dom.parent().parent().find('select').css("border-color","red");
            return false;
        }

        if (isNaN(mmsId) || mmsId === ''){
            $(".catalog-ingest-error").text("That MSS ID does not look right.");
            dom.parent().parent().find('.mss-id').css("border-color","red");
            return false;
        }


        //it is a number at least check with the server if it is already loaded
        $.get( "/collections/ingest/collection_exists", { id: mmsId} )
            .done(function( data ) {

                if (data.results){

                    $(".catalog-ingest-error").text("Collection already exists. Will not ingest.");

                }else{


                    //ingest it
                    $.get( "/collections/ingest/ingest_bnumber_from_interface", { bnumber: bnumber, org_unit_id: org, identifier_type : 'local_mss', identifier_value: mmsId})
                        .done(function( data ) {

                            if (data.error){
                                alert('There was a problem starting the ingest process: ' + data.message);
                            }else{

                                $(".tool-tip").tooltip('hide');

                                var e = $("#catalog-ingest-tr").first().clone();

                                $(".documents-new").append(e);
                                e.css('position','absolute')
                                    .css("top", $("#catalog-ingest-tr").first().offset().top+10)
                                    .css("max-width", $("#catalog-ingest-tr").first().width())
                                    .css("left", $("#catalog-ingest-tr").first().offset().left);

                                window.setTimeout(function(){
                                    e.addClass('transition');
                                    e.css("top", $("#status").offset().top + 10).css("opacity",0);
                                },10);


                                //it will likely sucessed, there are too fast to get feedback from the jobs table
                                //if it does not ingest it will not show up anyway
                                doneIds.push(parseInt(mmsId));


                                dom.parent().parent().find('.bnumber').val('');
                                dom.parent().parent().find('.mss-id').val('');
                                dom.parent().parent().find('select').val(-1);

                                window.setTimeout(function(){ingestUpdate(); e.remove();},1000);

                            }


                    });





                }

            });




    }



    function ingest_ead(filename,dom){

        //check if the mss id is set.

        var id = parseInt(dom.parent().parent().find('.mss-id').first().val());
        var org_unit = parseInt(dom.parent().parent().find('.org-unit-select').val());
        var filename = dom.parent().parent().find('.filename').first().data("filename");
        var bnumber = dom.parent().parent().find('.bnumber').first().val();


        if (!isNaN(id)){

            if (org_unit > 0){

                //it is a number at least check with the server if it is already loaded
                $.get( "/collections/ingest/collection_exists", { id: id} )
                    .done(function( data ) {

                        if (data.results){
                            dom.parent().parent().find('.filename').first().append($("<span>").html("<br>ERR: Collection<br>already exists.<br>Will not ingest.").css('color','red'));
                        }else{



                            
                            //ingest it
                            $.get( "/collections/ingest/ingest_ead_from_interface", { filename: filename, org_unit_id: org_unit, identifier_type : 'local_mss', identifier_value: id, bnumber : bnumber})
                                .done(function( data ) {

                                    if (data.error){
                                        alert('There was a problem starting the ingest process: ' + data.message);
                                    }else{

                                        $(".tool-tip").tooltip('hide');

                                        var top = $(dom).parent().parent().offset().top;

                                        $(dom).parent().parent().css("position","absolute").css("top",top);
                                        $(dom).parent().parent().css("top", $("#status").offset().top + 10).css("opacity",0);

                                        
                                        window.setTimeout(function(){ingestUpdate();},1000);
                                        
                                        if (ingestTimer == null){
                                            ingestTimer = window.setInterval(ingestUpdate,2500);
                                        }


                                    }


                                }

                            );                           


                        }

                    }
                );

            }else{
                dom.parent().parent().find('.org-unit-select').css('border-color','red');

            }

        }else{

            dom.parent().parent().find('.mss-id').css('border-color','red');

        }



    }

    function ingestUpdate(){

        $.get( "/collections/ingest/status")
            .done(function( data ) {

                if (data.active.length > 0 && ingestTimer == null){
                    ingestTimer = window.setInterval(ingestUpdate,2500);
                }


                $("#status .status-tr").remove();
                activeIds = [];
                $.each(data.active, function(i,e){

                    activeIds.push(parseInt(e.id));

                    var trClass = (e.status === 'Error') ? 'error' : 'info';
                    var status = "<span>" + e.status + "</span>";


                    if (e.is_locked){

                        if (e.component_count_done) {   
                            status = '<div class="progress progress-striped active"><div class="bar" style="width: ' + ((e.component_count_done / e.component_count ) * 100 )  + '%">' + e.status + '</div></div>';
                            if (e.component_count_done >= e.component_count){
                                trClass = 'success';     
                                status = 'Pending Complete';
                                doneIds.push(parseInt(e.id));
                            }
                        }

                    }else{
                        if (e.status !== "Error")
                            status = "Queued";
                    }




                    //hide that shheeettt
                    window.setTimeout(function(){$("#" + e.filename.replace(".xml",'')).hide();},1000);


                    $("#status")
                        .append(
                            $("<tr>")
                                .addClass(trClass)
                                .addClass('status-tr')
                                .append(
                                    $("<td>").text(e.id)
                                )
                                .append(
                                    $("<td>").text(e.filename)
                                )
                                .append(
                                    $("<td>").html(status)
                                )
                        );

                    if (e.status === 'Error'){
                        $("#status").append($("<tr>").addClass('status-tr').addClass(trClass).append( $("<td>").attr("colspan",3).text(e.raw.last_error)) );


                    }
                });


                //build the previously ingested
                $("#ingested .ingested-tr").remove();

                sucessfullyIngestedIds = [];

                $.each(data.previous, function(i,e){

                    sucessfullyIngestedIds.push(parseInt(e.identifier_value));


                    var doneClass = "";
                    if (doneIds.indexOf(parseInt(e.identifier_value)) > -1){
                        doneClass = "success";
                    }

                    $("#ingested")
                        .append(
                            $("<tr>")
                                .addClass('ingested-tr')
                                .addClass(doneClass)
                                .append(
                                    $("<td>").text(e.identifier_value)
                                )
                                .append(
                                    $("<td>").text(e.title)
                                )
                                .append(
                                    $("<td>").text(e.filename)
                                )
                                .append(
                                    $("<td>").text(e.updated_at)
                                )
                                .append(
                                    $("<td>").html('<a href="' + window.location.origin + '/' + e.code.toLowerCase() + '/' + e.identifier_value + '">Data</a> | ' + '<a href="' + window.location.origin.replace('data.','') + '/' + e.code.toLowerCase() + '/' + e.identifier_value + '">Portal</a>')
                                )
                        );
                });

            }
        ); 

    }

    function remove_tmp_ead(filename,dom){
        $.get( "/collections/ingest/remove_tmp_ead", { filename: filename} )
            .done(function( data ) {
                dom.parent().parent().remove();
            }
        );
    }

});

