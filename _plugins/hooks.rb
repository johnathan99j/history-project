Jekyll::Hooks.register :site, :pre_render do |site|
  Jekyll.logger.info "Generating data..."
  site.data["years_by_decade"] = site.collections["years"].by_decade
  site.data["shows_by_season"] = site.collections["shows"].by_season
  site.data["shows_by_play"] = site.collections["shows"].by_play
  site.data["shows_by_playwright"] = site.collections["shows"].by_playwright
  Jekyll.logger.info "Rendering site..."
end
