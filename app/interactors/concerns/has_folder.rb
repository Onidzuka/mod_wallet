module HasFolder
  def find_or_create_folder!(folder_id)
    Folder.find_or_create_by!(folder_id: folder_id)
  end
end
