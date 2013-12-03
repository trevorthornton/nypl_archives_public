$.fn.validateForm = function() {
  
  // This function adds or removes 'invalid' class and warning message from field
  $.fn.fieldValidationMarkup = function(valid,invalidClass,messageText) {
    inputName = $(this).attr('name');
    label = $("label[for='" + inputName + "']").first();
    if (valid == false) {
      if (!$(this).hasClass(invalidClass)) {
        // Add message to invalid field label
        $(label).append("<span class='validation-warning'>" + messageText + "</span>");
        // Add class to invalid field
        $(this).addClass(invalidClass);
        // Show error
        errornotice.fadeIn(750);
      }
    } else {
      // Remove invalid class/message
      $(this).removeClass(invalidClass);
      $(label).find('span.validation-warning').first().remove();
    }
  }
  
  $.fn.emailValidate = function() {
    var emailRegex = /^[a-zA-Z0-9_\.\-]+\@([a-zA-Z0-9\-]+\.)+([a-zA-Z0-9]{2,4})$/;
    return emailRegex.test($(this).val());
  }
  
  // Get IDs of required fields
  //required = [];
  //$(this).find(".required").each( function(i,r) {
  //  fieldId = $(r).attr('id');
  //  required.push(fieldId);
  //});
  
  // If using an ID other than #email or #error then replace it here
	//email = $("#email.required");
	//errornotice = $("#error");
  email = $(this).find("#email.required");
	errornotice = $(this).find("#error"); 


	// The text to show up within a field when it is incorrect
	emptyerror = "Please fill out this field.";
	emailerror = "Please enter a valid e-mail.";
	
	// Check that required fields are filled
  //for (i=0;i<required.length;i++) {
  //  input = $('#'+required[i]);
  //  if (input.val() == "") {
  //    $(input).fieldValidationMarkup(false,"needsfilled",emptyerror);
  //    console.log($(input));
  //  } else {
  //    $(input).fieldValidationMarkup(true,"needsfilled");
  //  }
  //}
  $(this).find(".required").each( function(i,r) {
    if ($(r).val() == "") {
      $(r).fieldValidationMarkup(false,"needsfilled",emptyerror);
    }else{
      $(r).fieldValidationMarkup(true,"needsfilled");
    }
  });


  // Validate email address format
  validEmail = $(email).emailValidate();
  if (validEmail == false) {
    $(email).first().fieldValidationMarkup(false,"needsfilled",emailerror);
  } else {
    $(email).first().fieldValidationMarkup(true,"needsfilled");

  }
  
  // if any inputs on the page have the class 'needsfilled' the form will not submit
  if ($(this).find('input, textarea').hasClass("needsfilled")) {
    return false;
  } else {
    errornotice.hide();
    return true;
  }
  
}



$(document).ready(function(){
  
  // Select between question and request materials
  $('.contact-form-choice').click(function() {
    formId = $(this).attr('data-choice') + "-form";
    console.log(formId);

    form = $("#" + formId);
    $(form).show();
    // $(otherForm).remove();
    $('#form-select').hide();
    return false
  });
  
  

  // All of this is triggered on clicking form submit
	$(document).on('click', ".contact-form input[type=submit]", function(e) {
    
    $(this).val('Sending...').attr("disabled", "disabled");


    form = $(this).parents('.contact-form').first();
    formId = $(form).parents('.form-wrapper').first().attr('id');
    // Validate    
    valid = $(form).validateForm();
    // Action
    if (valid == false) {
      $(this).val('Submit').removeAttr("disabled", "");
      return false;
    } else {      



      // Post form data
      $.ajax({
         type: "POST",
         url: $(form).attr('action'),
         data: $(form).serialize(), // serializes the form's elements.
         success: function(data) {
           // Show success message
           successId = formId + '-success'
           form.hide();
           $('h1.form-heading').hide();
           if ($("#layout_mode").val() === 'true'){
              $('#' + successId + '-static').show();
           }else{
              $('#' + successId).show();
           }
         }
       });
      return false;      
    }
    
    // Clears any fields in the form when the user clicks on them
    $("input, textarea").focus(function(){    
      if ($(this).hasClass("needsfilled") ) {
        $(this).removeClass("needsfilled");
      }
    });
  
	});

  
  
  $('a#form-success-close, a#form-cancel').click(function() {
    $.colorbox.close();
    return false;
  });
  
});