# Generated by BabelSDK

# DO NOT EDIT THIS FILE.
# This file is auto-generated from the babel template objects.babelt.rb.
# Any changes here will silently disappear.

require 'date'

module Dropbox
  module API

    # Converts a string date to a Date object
    def self.convert_date(str)
      DateTime.strptime(str, '%a, %d %b %Y %H:%M:%S')
    end

    # Photo-specific information derived from EXIF data.
    #
    # Required fields:
    # * +time_taken+ (+DateTime+) 
    #   When the photo was taken.
    # * +lat_long+ (+Array+) 
    #   The GPS coordinates where the photo was taken.
    class PhotoInfo
      attr_accessor(
          :time_taken,
          :lat_long
      )
    
      def initialize(
          time_taken,
          lat_long
      )
        @time_taken = time_taken
        @lat_long = lat_long
      end
    
      # Initializes an instance of PhotoInfo from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            Dropbox::API::convert_date(json['time_taken']),
            json['lat_long'].nil? ? nil : json['lat_long'],
        )
      end
    end
    
    # Video-specific information derived from EXIF data.
    #
    # Required fields:
    # * +time_taken+ (+DateTime+) 
    #   When the photo was taken.
    # * +lat_long+ (+Array+) 
    #   The GPS coordinates where the photo was taken.
    # * +duration+ (+Float+) 
    #   Length of video in milliseconds.
    class VideoInfo
      attr_accessor(
          :time_taken,
          :lat_long,
          :duration
      )
    
      def initialize(
          time_taken,
          lat_long,
          duration
      )
        @time_taken = time_taken
        @lat_long = lat_long
        @duration = duration
      end
    
      # Initializes an instance of VideoInfo from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            Dropbox::API::convert_date(json['time_taken']),
            json['lat_long'].nil? ? nil : json['lat_long'],
            json['duration'],
        )
      end
    end
    
    # This class is a tagged union. For more information on tagged unions,
    # see the README.
    #
    # Media specific information.
    #
    # Member types:
    # * +photo+ (+PhotoInfo+) 
    # * +video+ (+VideoInfo+) 
    class MediaInfo
    
      # Allowed tags for this union
      TAGS = [:photo, :video]
    
      def initialize(tag, val = nil)
        if !TAGS.include?(tag)
            fail ArgumentError, "Invalid symbol '#{ tag }' for this union."\
                " #{ TAGS }"
        end
        @tag = tag
        @val = val
      end
    
      # If the union's type is a symbol field, returns the symbol. If the type
      # is a struct, returns the struct. You can also use each individual
      # attribute accessor to retrieve the value for non-symbol union types.
      def value
        @val.nil? ? @tag : @val
      end
    
      # Returns this object as a hash for JSON conversion.
      def as_json(options = {})
        if @val.nil?
          @tag.to_s
        else
          { @tag => @val }
        end
      end
    
      # Initializes an instance of MediaInfo from
      # JSON-formatted data.
      def self.from_json(json)
        if json.is_a?(Hash)
          array = json.flatten
          if array.length != 2
            fail ArgumentError, "JSON should have one key/value pair."
          end
          tag = array[0].to_sym
          if tag == :photo
            val = PhotoInfo.from_json(array[1])
          end
          if tag == :video
            val = VideoInfo.from_json(array[1])
          end
        else
          # json is a String
          tag = json.to_sym
          val = nil
        end
        return self.new(tag, val)
      end
    
      # Initializes an instance of MediaInfo with the
      # photo tag.
      def self.photo
        self.new(:photo)
      end
    
      # Checks if this union has the +photo+ tag.
      def photo?
        @tag == :photo
      end
    
      # Retrieves the value for this union for the +photo+
      # tag.
      def photo
        if @tag == :photo
          @val
        else
          fail "Union is not this type."
        end
      end
    
      # Initializes an instance of MediaInfo with the
      # video tag.
      def self.video
        self.new(:video)
      end
    
      # Checks if this union has the +video+ tag.
      def video?
        @tag == :video
      end
    
      # Retrieves the value for this union for the +video+
      # tag.
      def video
        if @tag == :video
          @val
        else
          fail "Union is not this type."
        end
      end
    end
    
    # Information specific to a shared folder.
    #
    # Required fields:
    # * +id+ (+String+) 
    class SharedFolder
      attr_accessor(
          :id
      )
    
      def initialize(
          id
      )
        @id = id
      end
    
      # Initializes an instance of SharedFolder from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['id'],
        )
      end
    end
    
    # A file or folder entry.
    #
    # Required fields:
    # * +id+ (+String+) 
    #   A unique identifier for the file.
    # * +id_rev+ (+Integer+) 
    #   A unique identifier for the current revision of a file. This field is
    #   the same rev as elsewhere in the API and can be used to detect changes
    #   and avoid conflicts.
    # * +path+ (+String+) 
    #   Path to file or folder.
    # * +path_rev+ (+Integer+) 
    #   A unique identifier for the current revision of a file path. This
    #   field is the same rev as elsewhere in the API and can be used to
    #   detect changes and avoid conflicts.
    # * +shared_folder+ (+SharedFolder+) 
    #   If this a shared folder, information about it.
    # * +modified+ (+DateTime+) 
    #   The last time the file was modified on Dropbox, in the standard
    #   Timestamp format (+nil+ for root folder).
    # * +is_deleted+ (+boolean+) 
    #   Whether the given entry is deleted.
    class EntryInfo
      attr_accessor(
          :id,
          :id_rev,
          :path,
          :path_rev,
          :shared_folder,
          :modified,
          :is_deleted
      )
    
      def initialize(
          id,
          id_rev,
          path,
          path_rev,
          shared_folder,
          modified,
          is_deleted
      )
        @id = id
        @id_rev = id_rev
        @path = path
        @path_rev = path_rev
        @shared_folder = shared_folder
        @modified = modified
        @is_deleted = is_deleted
      end
    
      # Initializes an instance of EntryInfo from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['id'],
            json['id_rev'],
            json['path'],
            json['path_rev'],
            json['shared_folder'].nil? ? nil : SharedFolder.from_json(json['shared_folder']),
            json['modified'].nil? ? nil : Dropbox::API::convert_date(json['modified']),
            json['is_deleted'],
        )
      end
    end
    
    # Describes a file.
    #
    # Required fields:
    # * +id+ (+String+) 
    #   A unique identifier for the file.
    # * +id_rev+ (+Integer+) 
    #   A unique identifier for the current revision of a file. This field is
    #   the same rev as elsewhere in the API and can be used to detect changes
    #   and avoid conflicts.
    # * +path+ (+String+) 
    #   Path to file or folder.
    # * +path_rev+ (+Integer+) 
    #   A unique identifier for the current revision of a file path. This
    #   field is the same rev as elsewhere in the API and can be used to
    #   detect changes and avoid conflicts.
    # * +shared_folder+ (+SharedFolder+) 
    #   If this a shared folder, information about it.
    # * +modified+ (+DateTime+) 
    #   The last time the file was modified on Dropbox, in the standard
    #   Timestamp format (+nil+ for root folder).
    # * +is_deleted+ (+boolean+) 
    #   Whether the given entry is deleted.
    # * +size+ (+Integer+) 
    #   File size in bytes.
    # * +mime_type+ (+String+) 
    #   The Internet media type determined by the file extension.
    #
    # Optional fields:
    # * +media_info+ (+MediaInfo+) 
    #   Information specific to photo and video media.
    class FileInfo < EntryInfo
      attr_accessor(
          :size,
          :mime_type,
          :media_info
      )
    
      def initialize(
          id,
          id_rev,
          path,
          path_rev,
          shared_folder,
          modified,
          is_deleted,
          size,
          mime_type,
          media_info = nil
      )
        @id = id
        @id_rev = id_rev
        @path = path
        @path_rev = path_rev
        @shared_folder = shared_folder
        @modified = modified
        @is_deleted = is_deleted
        @size = size
        @mime_type = mime_type
        @media_info = media_info
      end
    
      # Initializes an instance of FileInfo from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['id'],
            json['id_rev'],
            json['path'],
            json['path_rev'],
            json['shared_folder'].nil? ? nil : SharedFolder.from_json(json['shared_folder']),
            json['modified'].nil? ? nil : Dropbox::API::convert_date(json['modified']),
            json['is_deleted'],
            json['size'],
            json['mime_type'].nil? ? nil : json['mime_type'],
            !json.include?('media_info') ? nil : MediaInfo.from_json(json['media_info']),
        )
      end
    end
    
    # Describes a folder.
    #
    # Required fields:
    # * +id+ (+String+) 
    #   A unique identifier for the file.
    # * +id_rev+ (+Integer+) 
    #   A unique identifier for the current revision of a file. This field is
    #   the same rev as elsewhere in the API and can be used to detect changes
    #   and avoid conflicts.
    # * +path+ (+String+) 
    #   Path to file or folder.
    # * +path_rev+ (+Integer+) 
    #   A unique identifier for the current revision of a file path. This
    #   field is the same rev as elsewhere in the API and can be used to
    #   detect changes and avoid conflicts.
    # * +shared_folder+ (+SharedFolder+) 
    #   If this a shared folder, information about it.
    # * +modified+ (+DateTime+) 
    #   The last time the file was modified on Dropbox, in the standard
    #   Timestamp format (+nil+ for root folder).
    # * +is_deleted+ (+boolean+) 
    #   Whether the given entry is deleted.
    class FolderInfo < EntryInfo
    
      def initialize(
          id,
          id_rev,
          path,
          path_rev,
          shared_folder,
          modified,
          is_deleted
      )
        @id = id
        @id_rev = id_rev
        @path = path
        @path_rev = path_rev
        @shared_folder = shared_folder
        @modified = modified
        @is_deleted = is_deleted
      end
    
      # Initializes an instance of FolderInfo from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['id'],
            json['id_rev'],
            json['path'],
            json['path_rev'],
            json['shared_folder'].nil? ? nil : SharedFolder.from_json(json['shared_folder']),
            json['modified'].nil? ? nil : Dropbox::API::convert_date(json['modified']),
            json['is_deleted'],
        )
      end
    end
    
    # This class is a tagged union. For more information on tagged unions,
    # see the README.
    #
    # A file or folder in a Dropbox.
    #
    # Member types:
    # * +file+ (+FileInfo+) 
    # * +folder+ (+FolderInfo+) 
    class FileOrFolderInfo
    
      # Allowed tags for this union
      TAGS = [:file, :folder]
    
      def initialize(tag, val = nil)
        if !TAGS.include?(tag)
            fail ArgumentError, "Invalid symbol '#{ tag }' for this union."\
                " #{ TAGS }"
        end
        @tag = tag
        @val = val
      end
    
      # If the union's type is a symbol field, returns the symbol. If the type
      # is a struct, returns the struct. You can also use each individual
      # attribute accessor to retrieve the value for non-symbol union types.
      def value
        @val.nil? ? @tag : @val
      end
    
      # Returns this object as a hash for JSON conversion.
      def as_json(options = {})
        if @val.nil?
          @tag.to_s
        else
          { @tag => @val }
        end
      end
    
      # Initializes an instance of FileOrFolderInfo from
      # JSON-formatted data.
      def self.from_json(json)
        if json.is_a?(Hash)
          array = json.flatten
          if array.length != 2
            fail ArgumentError, "JSON should have one key/value pair."
          end
          tag = array[0].to_sym
          if tag == :file
            val = FileInfo.from_json(array[1])
          end
          if tag == :folder
            val = FolderInfo.from_json(array[1])
          end
        else
          # json is a String
          tag = json.to_sym
          val = nil
        end
        return self.new(tag, val)
      end
    
      # Initializes an instance of FileOrFolderInfo with the
      # file tag.
      def self.file
        self.new(:file)
      end
    
      # Checks if this union has the +file+ tag.
      def file?
        @tag == :file
      end
    
      # Retrieves the value for this union for the +file+
      # tag.
      def file
        if @tag == :file
          @val
        else
          fail "Union is not this type."
        end
      end
    
      # Initializes an instance of FileOrFolderInfo with the
      # folder tag.
      def self.folder
        self.new(:folder)
      end
    
      # Checks if this union has the +folder+ tag.
      def folder?
        @tag == :folder
      end
    
      # Retrieves the value for this union for the +folder+
      # tag.
      def folder
        if @tag == :folder
          @val
        else
          fail "Union is not this type."
        end
      end
    end
    
    # Required fields:
    # * +id+ (+String+) 
    #   A unique identifier for the file.
    # * +id_rev+ (+Integer+) 
    #   A unique identifier for the current revision of a file. This field is
    #   the same rev as elsewhere in the API and can be used to detect changes
    #   and avoid conflicts.
    # * +path+ (+String+) 
    #   Path to file or folder.
    # * +path_rev+ (+Integer+) 
    #   A unique identifier for the current revision of a file path. This
    #   field is the same rev as elsewhere in the API and can be used to
    #   detect changes and avoid conflicts.
    # * +shared_folder+ (+SharedFolder+) 
    #   If this a shared folder, information about it.
    # * +modified+ (+DateTime+) 
    #   The last time the file was modified on Dropbox, in the standard
    #   Timestamp format (+nil+ for root folder).
    # * +is_deleted+ (+boolean+) 
    #   Whether the given entry is deleted.
    # * +contents+ (+Array+) 
    #   Ordered list of all contained files and folders.
    class FolderInfoAndContents < FolderInfo
      attr_accessor(
          :contents
      )
    
      def initialize(
          id,
          id_rev,
          path,
          path_rev,
          shared_folder,
          modified,
          is_deleted,
          contents
      )
        @id = id
        @id_rev = id_rev
        @path = path
        @path_rev = path_rev
        @shared_folder = shared_folder
        @modified = modified
        @is_deleted = is_deleted
        @contents = contents
      end
    
      # Initializes an instance of FolderInfoAndContents from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['id'],
            json['id_rev'],
            json['path'],
            json['path_rev'],
            json['shared_folder'].nil? ? nil : SharedFolder.from_json(json['shared_folder']),
            json['modified'].nil? ? nil : Dropbox::API::convert_date(json['modified']),
            json['is_deleted'],
            json['contents'].collect { |elem| FileOrFolderInfo.from_json(elem) },
        )
      end
    end
    
    
    
    # On a write conflict, overwrite the existing file if the parent rev
    # matches.
    #
    # Required fields:
    # * +parent_rev+ (+String+) 
    #   The revision to be updated.
    # * +auto_rename+ (+boolean+) 
    #   Whether the new file should be renamed on a conflict.
    class UpdateParentRev
      attr_accessor(
          :parent_rev,
          :auto_rename
      )
    
      def initialize(
          parent_rev,
          auto_rename
      )
        @parent_rev = parent_rev
        @auto_rename = auto_rename
      end
    
      # Initializes an instance of UpdateParentRev from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['parent_rev'],
            json['auto_rename'],
        )
      end
    end
    
    # This class is a tagged union. For more information on tagged unions,
    # see the README.
    #
    # Policy for managing write conflicts.
    #
    # Member types:
    # * +reject+ 
    #   On a write conflict, reject the new file.
    # * +overwrite+ 
    #   On a write conflict, overwrite the existing file.
    # * +rename+ 
    #   On a write conflict, rename the new file with a numerical suffix.
    # * +update_if_matching_parent_rev+ (+UpdateParentRev+) 
    #   On a write conflict, overwrite the existing file.
    class WriteConflictPolicy
    
      # Allowed tags for this union
      TAGS = [:reject, :overwrite, :rename, :update_if_matching_parent_rev]
    
      def initialize(tag, val = nil)
        if !TAGS.include?(tag)
            fail ArgumentError, "Invalid symbol '#{ tag }' for this union."\
                " #{ TAGS }"
        end
        @tag = tag
        @val = val
      end
    
      # If the union's type is a symbol field, returns the symbol. If the type
      # is a struct, returns the struct. You can also use each individual
      # attribute accessor to retrieve the value for non-symbol union types.
      def value
        @val.nil? ? @tag : @val
      end
    
      # Returns this object as a hash for JSON conversion.
      def as_json(options = {})
        if @val.nil?
          @tag.to_s
        else
          { @tag => @val }
        end
      end
    
      # Initializes an instance of WriteConflictPolicy from
      # JSON-formatted data.
      def self.from_json(json)
        if json.is_a?(Hash)
          array = json.flatten
          if array.length != 2
            fail ArgumentError, "JSON should have one key/value pair."
          end
          tag = array[0].to_sym
          if tag == :reject
            val = nil
          end
          if tag == :overwrite
            val = nil
          end
          if tag == :rename
            val = nil
          end
          if tag == :update_if_matching_parent_rev
            val = UpdateParentRev.from_json(array[1])
          end
        else
          # json is a String
          tag = json.to_sym
          val = nil
        end
        return self.new(tag, val)
      end
    
      # Initializes an instance of WriteConflictPolicy with the
      # reject tag.
      def self.reject
        self.new(:reject)
      end
    
      # Checks if this union has the +reject+ tag.
      def reject?
        @tag == :reject
      end
    
      # Initializes an instance of WriteConflictPolicy with the
      # overwrite tag.
      def self.overwrite
        self.new(:overwrite)
      end
    
      # Checks if this union has the +overwrite+ tag.
      def overwrite?
        @tag == :overwrite
      end
    
      # Initializes an instance of WriteConflictPolicy with the
      # rename tag.
      def self.rename
        self.new(:rename)
      end
    
      # Checks if this union has the +rename+ tag.
      def rename?
        @tag == :rename
      end
    
      # Initializes an instance of WriteConflictPolicy with the
      # update_if_matching_parent_rev tag.
      def self.update_if_matching_parent_rev
        self.new(:update_if_matching_parent_rev)
      end
    
      # Checks if this union has the +update_if_matching_parent_rev+ tag.
      def update_if_matching_parent_rev?
        @tag == :update_if_matching_parent_rev
      end
    
      # Retrieves the value for this union for the +update_if_matching_parent_rev+
      # tag.
      def update_if_matching_parent_rev
        if @tag == :update_if_matching_parent_rev
          @val
        else
          fail "Union is not this type."
        end
      end
    end
    
    
    
    # Required fields:
    # * +reset+ (+boolean+) 
    #   If , clear your local state before processing the delta entries. reset
    #   is always  on the initial call to Dropbox::API::Client::Files.delta`
    #   (i.e. when no cursor is passed in). Otherwise, it is  in rare
    #   situations, such as after server or account maintenance, or if a user
    #   deletes their app folder.
    # * +cursor+ (+String+) 
    #   A string that encodes the latest information that has been returned.
    #   On the next call to Dropbox::API::Client::Files.delta`, pass in this
    #   value.
    # * +has_more+ (+boolean+) 
    #   If , then there are more entries available; you can call
    #   Dropbox::API::Client::Files.delta` again immediately to retrieve those
    #   entries. If , then wait for at least five minutes (preferably longer)
    #   before checking again.
    # * +entries+ (+Array+) 
    #   Each file or directory that has been changed.
    class DeltaResponse
      attr_accessor(
          :reset,
          :cursor,
          :has_more,
          :entries
      )
    
      def initialize(
          reset,
          cursor,
          has_more,
          entries
      )
        @reset = reset
        @cursor = cursor
        @has_more = has_more
        @entries = entries
      end
    
      # Initializes an instance of DeltaResponse from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['reset'],
            json['cursor'],
            json['has_more'],
            json['entries'].collect { |elem| FileOrFolderInfo.from_json(elem) },
        )
      end
    end
    
    
    
    # The connection will block until there are changes available or a
    # timeout occurs.
    #
    # Required fields:
    # * +changes+ (+boolean+) 
    #   Indicates whether new changes are available. If this value is , you
    #   should call Dropbox::API::Client::Files.delta` to retrieve the
    #   changes. If this value is , it means the call to
    #   Dropbox::API::Client::Files.longpoll_delta` timed out.
    #
    # Optional fields:
    # * +backoff+ (+Integer+) 
    #   If present, the value indicates how many seconds your code should wait
    #   before calling Dropbox::API::Client::Files.longpoll_delta` again.
    class LongpollDeltaResponse
      attr_accessor(
          :changes,
          :backoff
      )
    
      def initialize(
          changes,
          backoff = nil
      )
        @changes = changes
        @backoff = backoff
      end
    
      # Initializes an instance of LongpollDeltaResponse from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['changes'],
            !json.include?('backoff') ? nil : json['backoff'],
        )
      end
    end
    
    
    # Required fields:
    # * +revisions+ (+Array+) 
    #   List of file or folders that have been part of the revision history.
    class RevisionHistory
      attr_accessor(
          :revisions
      )
    
      def initialize(
          revisions
      )
        @revisions = revisions
      end
    
      # Initializes an instance of RevisionHistory from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['revisions'].collect { |elem| FileOrFolderInfo.from_json(elem) },
        )
      end
    end
    
    
    
    # Required fields:
    # * +has_more+ (+boolean+) 
    #   If true, then the number of files found exceeds the file_limit.
    # * +results+ (+Array+) 
    #   List of file or folders that match the search query.
    class SearchResults
      attr_accessor(
          :has_more,
          :results
      )
    
      def initialize(
          has_more,
          results
      )
        @has_more = has_more
        @results = results
      end
    
      # Initializes an instance of SearchResults from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['has_more'],
            json['results'].collect { |elem| FileOrFolderInfo.from_json(elem) },
        )
      end
    end
    
    
    
    
    
    
    
    
    # The space quota info for a user.
    #
    # Required fields:
    # * +quota+ (+Integer+) 
    #   The user's total quota allocation (bytes).
    # * +normal+ (+Integer+) 
    #   The user's used quota outside of shared folders (bytes).
    # * +shared+ (+Integer+) 
    #   The user's used quota in shared folders (bytes).
    #
    # Optional fields:
    # * +datastores+ (+Integer+) 
    #   The user's used quota in datastores (bytes).
    class QuotaInfo
      attr_accessor(
          :quota,
          :normal,
          :shared,
          :datastores
      )
    
      def initialize(
          quota,
          normal,
          shared,
          datastores = nil
      )
        @quota = quota
        @normal = normal
        @shared = shared
        @datastores = datastores
      end
    
      # Initializes an instance of QuotaInfo from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['quota'],
            json['normal'],
            json['shared'],
            json['datastores'].nil? ? nil : json['datastores'],
        )
      end
    end
    
    # Information relevant to a team.
    #
    # Required fields:
    # * +name+ (+String+) 
    #   The name of the team.
    class Team
      attr_accessor(
          :name
      )
    
      def initialize(
          name
      )
        @name = name
      end
    
      # Initializes an instance of Team from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['name'],
        )
      end
    end
    
    # Information for a user's account.
    #
    # Required fields:
    # * +display_name+ (+String+) 
    #   The full name of a user.
    # * +account_id+ (+String+) 
    #   The user's unique Dropbox ID.
    # * +email+ (+String+) 
    #   The user's e-mail address.
    # * +country+ (+String+) 
    #   The user's two-letter country code, if available.
    # * +referral_link+ (+String+) 
    #   The user's referral link.
    # * +quota+ (+QuotaInfo+) 
    #   The user's quota.
    # * +is_paired+ (+boolean+) 
    #   Whether the user has a personal and business account.
    # * +team+ (+Team+) 
    #   If this paired account is a member of a team.
    class AccountInfo
      attr_accessor(
          :display_name,
          :account_id,
          :email,
          :country,
          :referral_link,
          :quota,
          :is_paired,
          :team
      )
    
      def initialize(
          display_name,
          account_id,
          email,
          country,
          referral_link,
          quota,
          is_paired,
          team
      )
        @display_name = display_name
        @account_id = account_id
        @email = email
        @country = country
        @referral_link = referral_link
        @quota = quota
        @is_paired = is_paired
        @team = team
      end
    
      # Initializes an instance of AccountInfo from
      # JSON-formatted data.
      def self.from_json(json)
        self.new(
            json['display_name'],
            json['account_id'],
            json['email'],
            json['country'],
            json['referral_link'],
            QuotaInfo.from_json(json['quota']),
            json['is_paired'],
            json['team'].nil? ? nil : Team.from_json(json['team']),
        )
      end
    end
    
    

    # This class is a wrapper around the Dropbox::API::FileInfo object that
    # provides some convenience methods for manipulating files. It includes
    # methods from the Dropbox::API::FileOps module.
    class File < FileInfo

      include FileOps

      attr_accessor :client

      def initialize(client, folder_info)
        super(*folder_info.instance_variables.collect do |name|
          a.instance_variable_get(name)
        end)
        @client = client
      end
    end

    # This class is a wrapper around the Dropbox::API::FolderInfo object that
    # provides some convenience methods for manipulating folders. It includes
    # methods from the Dropbox::API::FileOps module.
    class Folder < FolderInfo

      include FileOps

      attr_accessor :client

      class << self
        def create
          # TODO client method
        end
        alias_method :mkdir, :create
      end

      def initialize(client, folder_info)
        super(*folder_info.instance_variables.collect do |name|
          a.instance_variable_get(name)
        end)
        @client = client
      end
    end

  end
end