module Dropbox
  module API

    # Use this class to make Dropbox API calls.  You'll need to obtain an OAuth 2 access token
    # first; you can get one using either DropboxOAuth2Flow or DropboxOAuth2FlowNoRedirect.
    class DropboxClient

      # Args:
      # * +oauth2_access_token+: Obtained via DropboxOAuth2Flow or DropboxOAuth2FlowNoRedirect.
      # * +locale+: The user's current locale (used to localize error messages).
      def initialize(oauth2_access_token, root="auto", locale=nil)
        if oauth2_access_token.is_a?(String)
          @session = DropboxOAuth2Session.new(oauth2_access_token, locale)
        elsif oauth2_access_token.is_a?(DropboxSession)
          @session = oauth2_access_token
          @session.get_access_token
          if not locale.nil?
            @session.locale = locale
          end
        else
          raise ArgumentError.new("oauth2_access_token doesn't have a valid type")
        end

        @root = root.to_s  # If they passed in a symbol, make it a string

        if not ["dropbox","app_folder","auto"].include?(@root)
          raise ArgumentError.new("root must be :dropbox, :app_folder, or :auto")
        end
        if @root == "app_folder"
          #App Folder is the name of the access type, but for historical reasons
          #sandbox is the URL root component that indicates this
          @root = "sandbox"
        end
      end

      # Returns some information about the current user's Dropbox account (the "current user"
      # is the user associated with the access token you're using).
      #
      # For a detailed description of what this call returns, visit:
      # https://www.dropbox.com/developers/reference/api#account-info
      def account_info()
        response = @session.do_get "/account/info"
        Dropbox::parse_response(response)
      end

      # Disables the access token that this +DropboxClient+ is using.  If this call
      # succeeds, further API calls using this object will fail.
      def disable_access_token
        @session.do_post "/disable_access_token"
        nil
      end

      # If this +DropboxClient+ was created with an OAuth 1 access token, this method
      # can be used to create an equivalent OAuth 2 access token.  This can be used to
      # upgrade your app's existing access tokens from OAuth 1 to OAuth 2.
      def create_oauth2_access_token
        if not @session.is_a?(DropboxSession)
          raise ArgumentError.new("This call requires a DropboxClient that is configured with " \
                      "an OAuth 1 access token.")
        end
        response = @session.do_post "/oauth2/token_from_oauth1"
        Dropbox::parse_response(response)['access_token']
      end

      # Uploads a file to a server.  This uses the HTTP PUT upload method for simplicity
      #
      # Args:
      # * +to_path+: The directory path to upload the file to. If the destination
      #   directory does not yet exist, it will be created.
      # * +file_obj+: A file-like object to upload. If you would like, you can
      #   pass a string as file_obj.
      # * +overwrite+: Whether to overwrite an existing file at the given path. [default is False]
      #   If overwrite is False and a file already exists there, Dropbox
      #   will rename the upload to make sure it doesn't overwrite anything.
      #   You must check the returned metadata to know what this new name is.
      #   This field should only be True if your intent is to potentially
      #   clobber changes to a file that you don't know about.
      # * +parent_rev+: The rev field from the 'parent' of this upload. [optional]
      #   If your intent is to update the file at the given path, you should
      #   pass the parent_rev parameter set to the rev value from the most recent
      #   metadata you have of the existing file at that path. If the server
      #   has a more recent version of the file at the specified path, it will
      #   automatically rename your uploaded file, spinning off a conflict.
      #   Using this parameter effectively causes the overwrite parameter to be ignored.
      #   The file will always be overwritten if you send the most-recent parent_rev,
      #   and it will never be overwritten you send a less-recent one.
      # Returns:
      # * a Hash containing the metadata of the newly uploaded file.  The file may have a different
      #   name if it conflicted.
      #
      # Simple Example
      #  client = DropboxClient(oauth2_access_token)
      #  #session is a DropboxSession I've already authorized
      #  client.put_file('/test_file_on_dropbox', open('/tmp/test_file'))
      # This will upload the "/tmp/test_file" from my computer into the root of my App's app folder
      # and call it "test_file_on_dropbox".
      # The file will not overwrite any pre-existing file.
      def put_file(to_path, file_obj, overwrite=false, parent_rev=nil)
        path = "/files_put/#{@root}#{format_path(to_path)}"
        params = {
          'overwrite' => overwrite.to_s,
          'parent_rev' => parent_rev,
        }

        headers = {"Content-Type" => "application/octet-stream"}
        content_server = true
        response = @session.do_put path, params, headers, file_obj, content_server

        Dropbox::parse_response(response)
      end

      # Returns a ChunkedUploader object.
      #
      # Args:
      # * +file_obj+: The file-like object to be uploaded.  Must support .read()
      # * +total_size+: The total size of file_obj
      def get_chunked_uploader(file_obj, total_size)
        ChunkedUploader.new(self, file_obj, total_size)
      end

      # ChunkedUploader is responsible for uploading a large file to Dropbox in smaller chunks.
      # This allows large files to be uploaded and makes allows recovery during failure.
      class ChunkedUploader
        attr_accessor :file_obj, :total_size, :offset, :upload_id, :client

        def initialize(client, file_obj, total_size)
          @client = client
          @file_obj = file_obj
          @total_size = total_size
          @upload_id = nil
          @offset = 0
        end

        # Uploads data from this ChunkedUploader's file_obj in chunks, until
        # an error occurs. Throws an exception when an error occurs, and can
        # be called again to resume the upload.
        #
        # Args:
        # * +chunk_size+: The chunk size for each individual upload.  Defaults to 4MB.
        def upload(chunk_size=4*1024*1024)
          last_chunk = nil

          while @offset < @total_size
            if not last_chunk
              last_chunk = @file_obj.read(chunk_size)
            end

            resp = {}
            begin
              resp = Dropbox::parse_response(@client.partial_chunked_upload(last_chunk, @upload_id, @offset))
              last_chunk = nil
            rescue SocketError => e
              raise e
            rescue SystemCallError => e
              raise e
            rescue DropboxError => e
              raise e if e.http_response.nil? or e.http_response.code[0] == '5'
              begin
                resp = JSON.parse(e.http_response.body)
                raise DropboxError.new('server response does not have offset key') unless resp.has_key? 'offset'
              rescue JSON::ParserError
                raise DropboxError.new("Unable to parse JSON response: #{e.http_response.body}")
              end
            end

            if resp.has_key? 'offset' and resp['offset'] > @offset
              @offset += (resp['offset'] - @offset) if resp['offset']
              last_chunk = nil
            end
            @upload_id = resp['upload_id'] if resp['upload_id']
          end
        end

        # Completes a file upload
        #
        # Args:
        # * +to_path+: The directory path to upload the file to. If the destination
        #   directory does not yet exist, it will be created.
        # * +overwrite+: Whether to overwrite an existing file at the given path. [default is False]
        #   If overwrite is False and a file already exists there, Dropbox
        #   will rename the upload to make sure it doesn't overwrite anything.
        #   You must check the returned metadata to know what this new name is.
        #   This field should only be True if your intent is to potentially
        #   clobber changes to a file that you don't know about.
        # * parent_rev: The rev field from the 'parent' of this upload.
        #   If your intent is to update the file at the given path, you should
        #   pass the parent_rev parameter set to the rev value from the most recent
        #   metadata you have of the existing file at that path. If the server
        #   has a more recent version of the file at the specified path, it will
        #   automatically rename your uploaded file, spinning off a conflict.
        #   Using this parameter effectively causes the overwrite parameter to be ignored.
        #   The file will always be overwritten if you send the most-recent parent_rev,
        #   and it will never be overwritten you send a less-recent one.
        #
        # Returns:
        # *  A Hash with the metadata of file just uploaded.
        #    For a detailed description of what this call returns, visit:
        #    https://www.dropbox.com/developers/reference/api#metadata
        def finish(to_path, overwrite=false, parent_rev=nil)
          response = @client.commit_chunked_upload(to_path, @upload_id, overwrite, parent_rev)
          Dropbox::parse_response(response)
        end
      end

      def commit_chunked_upload(to_path, upload_id, overwrite=false, parent_rev=nil)  #:nodoc
        path = "/commit_chunked_upload/#{@root}#{format_path(to_path)}"
        params = {'overwrite' => overwrite.to_s,
              'upload_id' => upload_id,
              'parent_rev' => parent_rev,
            }
        headers = nil
        content_server = true
        @session.do_post path, params, headers, content_server
      end

      def partial_chunked_upload(data, upload_id=nil, offset=nil)  #:nodoc
        params = {
          'upload_id' => upload_id,
          'offset' => offset,
        }
        headers = {'Content-Type' => "application/octet-stream"}
        content_server = true
        @session.do_put '/chunked_upload', params, headers, data, content_server
      end

      # Download a file
      #
      # Args:
      # * +from_path+: The path to the file to be downloaded
      # * +rev+: A previous revision value of the file to be downloaded
      #
      # Returns:
      # * The file contents.
      def get_file(from_path, rev=nil)
        response = get_file_impl(from_path, rev)
        Dropbox::parse_response(response, raw=true)
      end

      # Download a file and get its metadata.
      #
      # Args:
      # * +from_path+: The path to the file to be downloaded
      # * +rev+: A previous revision value of the file to be downloaded
      #
      # Returns:
      # * The file contents.
      # * The file metadata as a hash.
      def get_file_and_metadata(from_path, rev=nil)
        response = get_file_impl(from_path, rev)
        parsed_response = Dropbox::parse_response(response, raw=true)
        metadata = parse_metadata(response)
        return parsed_response, metadata
      end

      # Download a file (helper method - don't call this directly).
      #
      # Args:
      # * +from_path+: The path to the file to be downloaded
      # * +rev+: A previous revision value of the file to be downloaded
      #
      # Returns:
      # * The HTTPResponse for the file download request.
      def get_file_impl(from_path, rev=nil) # :nodoc:
        path = "/files/#{@root}#{format_path(from_path)}"
        params = {
          'rev' => rev,
        }
        headers = nil
        content_server = true
        @session.do_get path, params, headers, content_server
      end
      private :get_file_impl

      # Parses out file metadata from a raw dropbox HTTP response.
      #
      # Args:
      # * +dropbox_raw_response+: The raw, unparsed HTTPResponse from Dropbox.
      #
      # Returns:
      # * The metadata of the file as a hash.
      def parse_metadata(dropbox_raw_response) # :nodoc:
        begin
          raw_metadata = dropbox_raw_response['x-dropbox-metadata']
          metadata = JSON.parse(raw_metadata)
        rescue
          raise DropboxError.new("Dropbox Server Error: x-dropbox-metadata=#{raw_metadata}",
                       dropbox_raw_response)
        end
        return metadata
      end
      private :parse_metadata

      # Copy a file or folder to a new location.
      #
      # Args:
      # * +from_path+: The path to the file or folder to be copied.
      # * +to_path+: The destination path of the file or folder to be copied.
      #   This parameter should include the destination filename (e.g.
      #   from_path: '/test.txt', to_path: '/dir/test.txt'). If there's
      #   already a file at the to_path, this copy will be renamed to
      #   be unique.
      #
      # Returns:
      # * A hash with the metadata of the new copy of the file or folder.
      #   For a detailed description of what this call returns, visit:
      #   https://www.dropbox.com/developers/reference/api#fileops-copy
      def file_copy(from_path, to_path)
        params = {
          "root" => @root,
          "from_path" => format_path(from_path, false),
          "to_path" => format_path(to_path, false),
        }
        response = @session.do_post "/fileops/copy", params
        Dropbox::parse_response(response)
      end

      # Create a folder.
      #
      # Arguments:
      # * +path+: The path of the new folder.
      #
      # Returns:
      # *  A hash with the metadata of the newly created folder.
      #    For a detailed description of what this call returns, visit:
      #    https://www.dropbox.com/developers/reference/api#fileops-create-folder
      def file_create_folder(path)
        params = {
          "root" => @root,
          "path" => format_path(path, false),
        }
        response = @session.do_post "/fileops/create_folder", params

        Dropbox::parse_response(response)
      end

      # Deletes a file
      #
      # Arguments:
      # * +path+: The path of the file to delete
      #
      # Returns:
      # *  A Hash with the metadata of file just deleted.
      #    For a detailed description of what this call returns, visit:
      #    https://www.dropbox.com/developers/reference/api#fileops-delete
      def file_delete(path)
        params = {
          "root" => @root,
          "path" => format_path(path, false),
        }
        response = @session.do_post "/fileops/delete", params
        Dropbox::parse_response(response)
      end

      # Moves a file
      #
      # Arguments:
      # * +from_path+: The path of the file to be moved
      # * +to_path+: The destination path of the file or folder to be moved
      #   If the file or folder already exists, it will be renamed to be unique.
      #
      # Returns:
      # *  A Hash with the metadata of file or folder just moved.
      #    For a detailed description of what this call returns, visit:
      #    https://www.dropbox.com/developers/reference/api#fileops-delete
      def file_move(from_path, to_path)
        params = {
          "root" => @root,
          "from_path" => format_path(from_path, false),
          "to_path" => format_path(to_path, false),
        }
        response = @session.do_post "/fileops/move", params
        Dropbox::parse_response(response)
      end

      # Retrives metadata for a file or folder
      #
      # Arguments:
      # * path: The path to the file or folder.
      # * list: Whether to list all contained files (only applies when
      #   path refers to a folder).
      # * file_limit: The maximum number of file entries to return within
      #   a folder. If the number of files in the directory exceeds this
      #   limit, an exception is raised. The server will return at max
      #   25,000 files within a folder.
      # * hash: Every directory listing has a hash parameter attached that
      #   can then be passed back into this function later to save on
      #   bandwidth. Rather than returning an unchanged folder's contents, if
      #   the hash matches a DropboxNotModified exception is raised.
      # * rev: Optional. The revision of the file to retrieve the metadata for.
      #   This parameter only applies for files. If omitted, you'll receive
      #   the most recent revision metadata.
      # * include_deleted: Specifies whether to include deleted files in metadata results.
      #
      # Returns:
      # * A Hash object with the metadata of the file or folder (and contained files if
      #   appropriate).  For a detailed description of what this call returns, visit:
      #   https://www.dropbox.com/developers/reference/api#metadata
      def metadata(path, file_limit=25000, list=true, hash=nil, rev=nil, include_deleted=false)
        params = {
          "file_limit" => file_limit.to_s,
          "list" => list.to_s,
          "include_deleted" => include_deleted.to_s,
          "hash" => hash,
          "rev" => rev,
        }

        response = @session.do_get "/metadata/#{@root}#{format_path(path)}", params
        if response.kind_of? Net::HTTPRedirection
          raise DropboxNotModified.new("metadata not modified")
        end
        Dropbox::parse_response(response)
      end

      # Search directory for filenames matching query
      #
      # Arguments:
      # * path: The directory to search within
      # * query: The query to search on (3 character minimum)
      # * file_limit: The maximum number of file entries to return/
      #   If the number of files exceeds this
      #   limit, an exception is raised. The server will return at max 1,000
      # * include_deleted: Whether to include deleted files in search results
      #
      # Returns:
      # * A Hash object with a list the metadata of the file or folders matching query
      #   inside path.  For a detailed description of what this call returns, visit:
      #   https://www.dropbox.com/developers/reference/api#search
      def search(path, query, file_limit=1000, include_deleted=false)
        params = {
          'query' => query,
          'file_limit' => file_limit.to_s,
          'include_deleted' => include_deleted.to_s
        }

        response = @session.do_get "/search/#{@root}#{format_path(path)}", params
        Dropbox::parse_response(response)
      end

      # Retrive revisions of a file
      #
      # Arguments:
      # * path: The file to fetch revisions for. Note that revisions
      #   are not available for folders.
      # * rev_limit: The maximum number of file entries to return within
      #   a folder. The server will return at max 1,000 revisions.
      #
      # Returns:
      # * A Hash object with a list of the metadata of the all the revisions of
      #   all matches files (up to rev_limit entries)
      #   For a detailed description of what this call returns, visit:
      #   https://www.dropbox.com/developers/reference/api#revisions
      def revisions(path, rev_limit=1000)
        params = {
          'rev_limit' => rev_limit.to_s
        }

        response = @session.do_get "/revisions/#{@root}#{format_path(path)}", params
        Dropbox::parse_response(response)
      end

      # Restore a file to a previous revision.
      #
      # Arguments:
      # * path: The file to restore. Note that folders can't be restored.
      # * rev: A previous rev value of the file to be restored to.
      #
      # Returns:
      # * A Hash object with a list the metadata of the file or folders restored
      #   For a detailed description of what this call returns, visit:
      #   https://www.dropbox.com/developers/reference/api#search
      def restore(path, rev)
        params = {
          'rev' => rev.to_s
        }

        response = @session.do_post "/restore/#{@root}#{format_path(path)}", params
        Dropbox::parse_response(response)
      end

      # Returns a direct link to a media file
      # All of Dropbox's API methods require OAuth, which may cause problems in
      # situations where an application expects to be able to hit a URL multiple times
      # (for example, a media player seeking around a video file). This method
      # creates a time-limited URL that can be accessed without any authentication.
      #
      # Arguments:
      # * path: The file to stream.
      #
      # Returns:
      # * A Hash object that looks like the following:
      #      {'url': 'https://dl.dropboxusercontent.com/1/view/abcdefghijk/example', 'expires': 'Thu, 16 Sep 2011 01:01:25 +0000'}
      def media(path)
        response = @session.do_get "/media/#{@root}#{format_path(path)}"
        Dropbox::parse_response(response)
      end

      # Get a URL to share a media file
      # Shareable links created on Dropbox are time-limited, but don't require any
      # authentication, so they can be given out freely. The time limit should allow
      # at least a day of shareability, though users have the ability to disable
      # a link from their account if they like.
      #
      # Arguments:
      # * path: The file to share.
      # * short_url: When true (default), the url returned will be shortened using the Dropbox url shortener. If false,
      #   the url will link directly to the file's preview page.
      #
      # Returns:
      # * A Hash object that looks like the following example:
      #      {'url': 'https://db.tt/c0mFuu1Y', 'expires': 'Tue, 01 Jan 2030 00:00:00 +0000'}
      #   For a detailed description of what this call returns, visit:
      #    https://www.dropbox.com/developers/reference/api#shares
      def shares(path, short_url=true)
        response = @session.do_get "/shares/#{@root}#{format_path(path)}", {"short_url"=>short_url}
        Dropbox::parse_response(response)
      end

      # Download a thumbnail for an image.
      #
      # Arguments:
      # * from_path: The path to the file to be thumbnailed.
      # * size: A string describing the desired thumbnail size. At this time,
      #   'small' (32x32), 'medium' (64x64), 'large' (128x128), 's' (64x64),
      #   'm' (128x128), 'l' (640x640), and 'xl' (1024x1024) are officially supported sizes.
      #   Check https://www.dropbox.com/developers/reference/api#thumbnails
      #   for more details. [defaults to large]
      # Returns:
      # * The thumbnail data
      def thumbnail(from_path, size='large')
        response = thumbnail_impl(from_path, size)
        Dropbox::parse_response(response, raw=true)
      end

      # Download a thumbnail for an image along with the image's metadata.
      #
      # Arguments:
      # * from_path: The path to the file to be thumbnailed.
      # * size: A string describing the desired thumbnail size. See thumbnail()
      #   for details.
      # Returns:
      # * The thumbnail data
      # * The metadata for the image as a hash
      def thumbnail_and_metadata(from_path, size='large')
        response = thumbnail_impl(from_path, size)
        parsed_response = Dropbox::parse_response(response, raw=true)
        metadata = parse_metadata(response)
        return parsed_response, metadata
      end

      # A way of letting you keep a local representation of the Dropbox folder
      # heirarchy.  You can periodically call delta() to get a list of "delta
      # entries", which are instructions on how to update your local state to
      # match the server's state.
      #
      # Arguments:
      # * +cursor+: On the first call, omit this argument (or pass in +nil+).  On
      #   subsequent calls, pass in the +cursor+ string returned by the previous
      #   call.
      # * +path_prefix+: If provided, results will be limited to files and folders
      #   whose paths are equal to or under +path_prefix+.  The +path_prefix+ is
      #   fixed for a given cursor.  Whatever +path_prefix+ you use on the first
      #   +delta()+ must also be passed in on subsequent calls that use the returned
      #   cursor.
      #
      # Returns: A hash with three fields.
      # * +entries+: A list of "delta entries" (described below)
      # * +reset+: If +true+, you should reset local state to be an empty folder
      #   before processing the list of delta entries.  This is only +true+ only
      #   in rare situations.
      # * +cursor+: A string that is used to keep track of your current state.
      #   On the next call to delta(), pass in this value to return entries
      #   that were recorded since the cursor was returned.
      # * +has_more+: If +true+, then there are more entries available; you can
      #   call delta() again immediately to retrieve those entries.  If +false+,
      #   then wait at least 5 minutes (preferably longer) before checking again.
      #
      # Delta Entries: Each entry is a 2-item list of one of following forms:
      # * [_path_, _metadata_]: Indicates that there is a file/folder at the given
      #   path.  You should add the entry to your local state.  (The _metadata_
      #   value is the same as what would be returned by the #metadata() call.)
      #   * If the path refers to parent folders that don't yet exist in your
      #     local state, create those parent folders in your local state.  You
      #     will eventually get entries for those parent folders.
      #   * If the new entry is a file, replace whatever your local state has at
      #     _path_ with the new entry.
      #   * If the new entry is a folder, check what your local state has at
      #     _path_.  If it's a file, replace it with the new entry.  If it's a
      #     folder, apply the new _metadata_ to the folder, but do not modify
      #     the folder's children.
      # * [path, +nil+]: Indicates that there is no file/folder at the _path_ on
      #   Dropbox.  To update your local state to match, delete whatever is at
      #   _path_, including any children (you will sometimes also get separate
      #   delta entries for each child, but this is not guaranteed).  If your
      #   local state doesn't have anything at _path_, ignore this entry.
      #
      # Remember: Dropbox treats file names in a case-insensitive but case-preserving
      # way.  To facilitate this, the _path_ strings above are lower-cased versions of
      # the actual path.  The _metadata_ dicts have the original, case-preserved path.
      def delta(cursor=nil, path_prefix=nil)
        params = {
          'cursor' => cursor,
          'path_prefix' => path_prefix,
        }

        response = @session.do_post "/delta", params
        Dropbox::parse_response(response)
      end

      # Download a thumbnail (helper method - don't call this directly).
      #
      # Args:
      # * +from_path+: The path to the file to be thumbnailed.
      # * +size+: A string describing the desired thumbnail size. See thumbnail()
      #   for details.
      #
      # Returns:
      # * The HTTPResponse for the thumbnail request.
      def thumbnail_impl(from_path, size='large') # :nodoc:
        path = "/thumbnails/#{@root}#{format_path(from_path, true)}"
        params = {
          "size" => size
        }
        headers = nil
        content_server = true
        @session.do_get path, params, headers, content_server
      end
      private :thumbnail_impl


      # Creates and returns a copy ref for a specific file.  The copy ref can be
      # used to instantly copy that file to the Dropbox of another account.
      #
      # Args:
      # * +path+: The path to the file for a copy ref to be created on.
      #
      # Returns:
      # * A Hash object that looks like the following example:
      #      {"expires"=>"Fri, 31 Jan 2042 21:01:05 +0000", "copy_ref"=>"z1X6ATl6aWtzOGq0c3g5Ng"}
      def create_copy_ref(path)
        path = "/copy_ref/#{@root}#{format_path(path)}"
        response = @session.do_get path
        Dropbox::parse_response(response)
      end

      # Adds the file referenced by the copy ref to the specified path
      #
      # Args:
      # * +copy_ref+: A copy ref string that was returned from a create_copy_ref call.
      #   The copy_ref can be created from any other Dropbox account, or from the same account.
      # * +to_path+: The path to where the file will be created.
      #
      # Returns:
      # * A hash with the metadata of the new file.
      def add_copy_ref(to_path, copy_ref)
        params = {'from_copy_ref' => copy_ref,
              'to_path' => "#{to_path}",
              'root' => @root}

        response = @session.do_post "/fileops/copy", params
        Dropbox::parse_response(response)
      end

      #From the oauth spec plus "/".  Slash should not be ecsaped
      RESERVED_CHARACTERS = /[^a-zA-Z0-9\-\.\_\~\/]/  # :nodoc:

      def format_path(path, escape=true) # :nodoc:
        path = path.gsub(/\/+/,"/")
        # replace multiple slashes with a single one

        path = path.gsub(/^\/?/,"/")
        # ensure the path starts with a slash

        path.gsub(/\/?$/,"")
        # ensure the path doesn't end with a slash

        return URI.escape(path, RESERVED_CHARACTERS) if escape
        path
      end

    end
  end
end