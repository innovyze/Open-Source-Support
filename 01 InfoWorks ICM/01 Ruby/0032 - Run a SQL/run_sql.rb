on = WSApplication.current_network
query = "SELECT COUNT(conduit_height) AS Count INTO FILE 'C:\\DELETE\\TEST.CSV'"\
		"GROUP BY conduit_height AS Height"
on.run_SQL('_links',query)