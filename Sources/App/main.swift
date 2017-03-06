import Vapor

let drop = Droplet()

drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

let thingController = ThingController()
drop.get("things", String.self, handler: thingController.get)
drop.get("slack", handler: thingController.slack)

drop.run()
