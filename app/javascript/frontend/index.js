// Load dependencies
// Load styles
import './styles'

// View statistics
import './scripts/view_statistics_chart'

// Load dependencies
var $ = require('jquery/dist/jquery')
require('bootstrap/dist/js/bootstrap')

// Load Blacklight dependencies
// This should be just enough JS to get the facet modals working.
require('blacklight-frontend/app/javascript/blacklight/core')
require('blacklight-frontend/app/javascript/blacklight/modal')
require('blacklight-frontend/app/javascript/blacklight/facet_load')

// Load images
// Retrieve the path to the image via <%= image_pack_tag('image.png') %>
require.context('./img/', true)

// Initialize tooltips
$(function () {
  $('[data-toggle="tooltip"]').tooltip()
})
