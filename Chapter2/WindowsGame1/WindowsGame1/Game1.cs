#region Using Statements
using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Storage;
using System.Diagnostics;
using VTFTutorial;
#endregion

namespace Chapter1
{
    /// <summary>
    /// This is the main type for your game
    /// </summary>
    public class Game1 : Microsoft.Xna.Framework.Game
    {
        GraphicsDeviceManager graphics;
        
        Camera camera;
        Grid grid;
        
        Effect gridEffect;
        Effect WaterCalc;

        SpriteFont font;

        Texture2D debugTexture;
        Effect debugEffect;

        // flux is short form for Flow Velocity (Virtual Pipe Model)
        Texture2D fluxTexture;
        Texture2D groundTexture;
        Texture2D waterTexture;
        Texture2D waterSourceTexture;

        Texture2D sandTexture, grassTexture, rockTexture, snowTexture;
        

        RenderTarget2D[] water_rt;
        RenderTarget2D[] ground_rt;
        RenderTarget2D[] water_flux_rt;

        RenderTarget2D added_water_rt;
        //RenderTarget2D current_flux_rt;

        RenderTargetBinding[][] rtb;

        //RenderTarget2D rt1, rt2;

        public Game1()
        {
            graphics = new GraphicsDeviceManager(this);
            //content = new ContentManager(Services);

            camera = new Camera(this);
            Components.Add(camera);

            grid = new Grid(this);
            grid.CellSize = 4;
            grid.Dimension = 256;
            
            Content.RootDirectory = "Content";
        }


        /// <summary>
        /// Allows the game to perform any initialization it needs to before starting to run.
        /// This is where it can query for any required services and load any non-graphic
        /// related content.  Calling base.Initialize will enumerate through any components
        /// and initialize them as well.
        /// </summary>
        protected override void Initialize()
        {
            // TODO: Add your initialization logic here

            base.Initialize();
        }

        static Color[] data = null;
        static Vector4[] newData = null;

        Texture2D convertToColorTexture(Texture2D tex)
        {
            if (data == null || data.Length != tex.Width * tex.Height)
                data = new Color[tex.Width * tex.Height];
            if (newData == null || newData.Length != tex.Width * tex.Height)
                newData = new Vector4[tex.Width * tex.Height];

            tex.GetData<Vector4>(newData);
            float mult = 255.0f;
            for (int i = 0; i < tex.Width * tex.Height; i++)
            {
                data[i].R = (byte)(newData[i].X * mult);
                data[i].G = (byte)(newData[i].Y * mult);
                data[i].B = (byte)(newData[i].Z * mult);
                data[i].A = (byte)(newData[i].W * mult);
            }

            Texture2D ret = new Texture2D(graphics.GraphicsDevice, tex.Width, tex.Height, false, SurfaceFormat.Color);
            ret.SetData<Color>(data);
            return ret;

        }

        Texture2D convertToVec4Texture(Texture2D tex)
        {
            if(data == null || data.Length != tex.Width * tex.Height)
                data = new Color[tex.Width * tex.Height];
            if (newData == null || newData.Length != tex.Width * tex.Height)
                newData = new Vector4[tex.Width * tex.Height];

            tex.GetData<Color>(data);
            float mult = 1.0f / 255.0f;
            for (int i = 0; i < tex.Width * tex.Height; i++)
            {
                newData[i].X = data[i].R * mult;
                newData[i].Y = data[i].G * mult;
                newData[i].Z = data[i].B * mult;
                newData[i].W = data[i].A * mult;
            }

            Texture2D ret = new Texture2D(graphics.GraphicsDevice, tex.Width, tex.Height, false, SurfaceFormat.Vector4);
            ret.SetData<Vector4>(newData);
            return ret;

        }

        /// <summary>
        /// Load your graphics content.  If loadAllContent is true, you should
        /// load content from both ResourceManagementMode pools.  Otherwise, just
        /// load ResourceManagementMode.Manual content.
        /// </summary>
        /// <param name="loadAllContent">Which type of content to load.</param>
        protected override void LoadContent()
        {
            grid.LoadContent();
            
            //  EFFECTS
            gridEffect = Content.Load<Effect>("VTFDisplacement");
            WaterCalc = Content.Load<Effect>("WaterCalc");
            debugEffect = Content.Load<Effect>("DebugEffect");

            // CALC TEXTURES
            groundTexture= convertToVec4Texture(Content.Load<Texture2D>("Textures\\heightmap2"));
            waterSourceTexture = convertToVec4Texture(Content.Load<Texture2D>("Textures\\water"));
            waterTexture= convertToVec4Texture(Content.Load<Texture2D>("Textures\\water"));
            fluxTexture = new Texture2D(graphics.GraphicsDevice, 512, 512, false, SurfaceFormat.Vector4);
            Vector4[] newData = new Vector4[fluxTexture.Width * fluxTexture.Height];
            for (int i = 0; i < fluxTexture.Width * fluxTexture.Height; i++)
                newData[i] = new Vector4(0, 0, 0, 0);
            fluxTexture.SetData<Vector4>(newData);

            // VISUAL TEXTURES
            sandTexture = Content.Load<Texture2D>("Textures\\sand");
            grassTexture = Content.Load<Texture2D>("Textures\\grass");
            rockTexture = Content.Load<Texture2D>("Textures\\rock");
            snowTexture = Content.Load<Texture2D>("Textures\\snow");

            debugTexture = Content.Load<Texture2D>("Textures\\sun");

            font = Content.Load<SpriteFont>("MyArial");

            PresentationParameters pp = graphics.GraphicsDevice.PresentationParameters;

                        

            water_rt = new RenderTarget2D[2];
            water_rt[0] = new RenderTarget2D(graphics.GraphicsDevice, 512, 512,
                false, SurfaceFormat.Vector4, DepthFormat.None, 0, RenderTargetUsage.PlatformContents);
            water_rt[1] = new RenderTarget2D(graphics.GraphicsDevice, 512, 512,
                false, SurfaceFormat.Vector4, DepthFormat.None, 0, RenderTargetUsage.PlatformContents);

            ground_rt = new RenderTarget2D[2];
            ground_rt[0] = new RenderTarget2D(graphics.GraphicsDevice, 512, 512,
                false, SurfaceFormat.Vector4, DepthFormat.None, 0, RenderTargetUsage.PlatformContents);
            ground_rt[1] = new RenderTarget2D(graphics.GraphicsDevice, 512, 512,
                false, SurfaceFormat.Vector4, DepthFormat.None, 0, RenderTargetUsage.PlatformContents);

            water_flux_rt = new RenderTarget2D[2];
            water_flux_rt[0] = new RenderTarget2D(graphics.GraphicsDevice, 512, 512,
                false, SurfaceFormat.Color, DepthFormat.None, 0, RenderTargetUsage.PlatformContents);
            water_flux_rt[1] = new RenderTarget2D(graphics.GraphicsDevice, 512, 512,
                false, SurfaceFormat.Color, DepthFormat.None, 0, RenderTargetUsage.PlatformContents);

            added_water_rt = new RenderTarget2D(graphics.GraphicsDevice, 512, 512,
                false, SurfaceFormat.Vector4, DepthFormat.None, 0, RenderTargetUsage.PlatformContents);


            rtb = new RenderTargetBinding[2][];
            for (int i = 0; i < 2; i++)
            {
                rtb[i] = new RenderTargetBinding[2]
                {
                    new RenderTargetBinding(water_rt[i]),
                    new RenderTargetBinding(ground_rt[i]),
                };
            }
        }


        /// <summary>
        /// Unload your graphics content.  If unloadAllContent is true, you should
        /// unload content from both ResourceManagementMode pools.  Otherwise, just
        /// unload ResourceManagementMode.Manual content.  Manual content will get
        /// Disposed by the GraphicsDevice during a Reset.
        /// </summary>
        /// <param name="unloadAllContent">Which type of content to unload.</param>
        protected override void UnloadContent()
        {
        }


        /// <summary>
        /// Allows the game to run logic such as updating the world,
        /// checking for collisions, gathering input and playing audio.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Update(GameTime gameTime)
        {
            // Allows the game to exit
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed)
                this.Exit();

            // TODO: Add your update logic here

            base.Update(gameTime);
        }

        int act_water_rt = 0;
        void calculateWater(float dt)
        {
            //Debug.WriteLine(String.Format("{0:0.000}", dt));

            using (SpriteBatch sprite = new SpriteBatch(graphics.GraphicsDevice))
            {
                SamplerState ss = new SamplerState();
                ss.Filter = TextureFilter.Point;

                WaterCalc.Parameters["time"].SetValue(dt);
                graphics.GraphicsDevice.Textures[1] = (waterSourceTexture);
                graphics.GraphicsDevice.Textures[2] = groundTexture;
                graphics.GraphicsDevice.Textures[3] = fluxTexture;

                graphics.GraphicsDevice.SamplerStates[1] = ss;
                graphics.GraphicsDevice.SamplerStates[2] = ss;
                graphics.GraphicsDevice.SamplerStates[3] = ss;

                // PASS 1 - WATER ADD
                WaterCalc.CurrentTechnique = WaterCalc.Techniques["WaterAddCalc"];
                graphics.GraphicsDevice.SetRenderTarget(added_water_rt);

                sprite.Begin(0, BlendState.Opaque, ss, null, null, WaterCalc);
                sprite.Draw(waterTexture, new Rectangle(0, 0, added_water_rt.Width, added_water_rt.Height), Color.White);
                sprite.End();

                waterTexture = (Texture2D)added_water_rt;
                
                // PASS 2 - FLUX
                WaterCalc.CurrentTechnique = WaterCalc.Techniques["FluxCalculation"];
                graphics.GraphicsDevice.SetRenderTarget(water_flux_rt[act_water_rt]);
                
                sprite.Begin(0, BlendState.Opaque, ss, null, null, WaterCalc);
                sprite.Draw(waterTexture, new Rectangle(0, 0, water_flux_rt[act_water_rt].Width, water_flux_rt[act_water_rt].Height), Color.White);
                sprite.End();

                fluxTexture = (Texture2D)water_flux_rt[act_water_rt];
                graphics.GraphicsDevice.SetRenderTarget(null);
                graphics.GraphicsDevice.Textures[3] = fluxTexture;

                // PASS 3 WATER
                WaterCalc.CurrentTechnique = WaterCalc.Techniques["WaterCalculation"];

                graphics.GraphicsDevice.SetRenderTarget(water_rt[1 - act_water_rt]);
                graphics.GraphicsDevice.Clear(new Color(0, 0, 0, 0));
                sprite.Begin(0, BlendState.Opaque, ss, null, null, WaterCalc);
                sprite.Draw(added_water_rt, new Rectangle(0, 0, water_rt[act_water_rt].Width, water_rt[act_water_rt].Height), Color.White);
                sprite.End();

                graphics.GraphicsDevice.SetRenderTarget(null);

                // PASS 4 WATER EVAP
                WaterCalc.CurrentTechnique = WaterCalc.Techniques["EvaporationCalculation"];

                graphics.GraphicsDevice.SetRenderTarget(water_rt[act_water_rt]);
                sprite.Begin(0, BlendState.Opaque, ss, null, null, WaterCalc);
                sprite.Draw(water_rt[1 - act_water_rt], new Rectangle(0, 0, water_rt[act_water_rt].Width, water_rt[act_water_rt].Height), Color.White);
                sprite.End();

                graphics.GraphicsDevice.SetRenderTarget(null);

                waterTexture = (Texture2D)water_rt[act_water_rt];
            }

            act_water_rt = 1 - act_water_rt;
        }


        private static float time = 0;
        private static int frames = 0;
        static float fps = 0;
        /// <summary>
        /// This is called when the game should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            time += gameTime.ElapsedGameTime.Milliseconds;
            frames++;
            if (time > 1000)
            {
                fps = (float)frames;
                time = 0;
                frames = 0;
            }

            calculateWater(34 * .001f);//Math.Min(gameTime.ElapsedGameTime.Milliseconds * 0.001f, 34 * 0.001f));

            graphics.GraphicsDevice.Clear(Color.CornflowerBlue);
            //graphics.GraphicsDevice.RenderState.CullMode = CullMode.None;
            
            gridEffect.CurrentTechnique = gridEffect.Techniques["GridDraw"];
            gridEffect.Parameters["world"].SetValue(Matrix.Identity);
            gridEffect.Parameters["view"].SetValue(camera.View);
            gridEffect.Parameters["proj"].SetValue(camera.Projection);
            gridEffect.Parameters["maxHeight"].SetValue(128);
            gridEffect.Parameters["displacementMap"].SetValue(groundTexture);
            gridEffect.Parameters["waterMap"].SetValue(waterTexture);

            gridEffect.Parameters["sandMap"].SetValue(sandTexture);
            gridEffect.Parameters["grassMap"].SetValue(grassTexture);
            gridEffect.Parameters["rockMap"].SetValue(rockTexture);
            gridEffect.Parameters["snowMap"].SetValue(snowTexture);

            foreach (EffectPass pass in gridEffect.CurrentTechnique.Passes)
            {
                pass.Apply();
                grid.Draw();
             
            }

            using (SpriteBatch sprite = new SpriteBatch(graphics.GraphicsDevice))
            {
                SamplerState ss = new SamplerState();
                ss.Filter = TextureFilter.Point;

                sprite.Begin(0, BlendState.AlphaBlend, ss, null, null);
                //sprite.Draw(waterTexture, new Rectangle(0, 0, 240, 240), Color.White);
                sprite.Draw(waterTexture, new Rectangle(0, 0, 512, 512), Color.White);
                sprite.DrawString(font, String.Format("{0}", (int)fps), new Vector2(0, 0), Color.Red);
                sprite.End();

                //debugEffect.CurrentTechnique = debugEffect.Techniques["DebugTechnique"];
                //sprite.Begin(0, BlendState.AlphaBlend, null, null, null, debugEffect);
                //sprite.Draw(debugTexture, new Rectangle(0, 0, 512, 512), Color.White);
                //sprite.End();

            }

            base.Draw(gameTime);
        }
    }
}
