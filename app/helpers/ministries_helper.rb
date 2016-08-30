module MinistriesHelper
    def location_name(ministry)
    if location = ministry.location_id
      Location.find(ministry.location_id).name
    else
      "Pending Location"
    end
  end
end
