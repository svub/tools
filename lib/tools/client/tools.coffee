
### alerts ############################################################################################################

u.alert = (message, type = 'info', delay = 6000) -> 
  $.bootstrapGrowl message,
    # ele: 'body'                          # which element to append to
    type:   type                           # null, 'info', 'error', 'success'
    offset: { from: 'top', amount: ($('header').outerHeight() + 10) } # do not overlay header
    align:  (if type == 'info' then 'right' else 'center')                       # 'left', 'right', or 'center'
    width:  250                           # integer, or 'auto'
    delay:  delay
    allow_dismiss: (not (type in ['error', 'danger']))
    stackup_spacing: 10                  # spacing between consecutively stacked growls.

u.alert.warning = (message) -> u.alert message, 'warning'
u.alert.error = (message) -> u.alert message, 'danger', 8000
u.alert.success = (message) -> u.alert message, 'success'

